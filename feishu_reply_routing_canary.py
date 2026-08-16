"""Secret-free runtime canary for Feishu quote/topic routing."""

from __future__ import annotations

import asyncio
from types import SimpleNamespace
from unittest.mock import AsyncMock, Mock

from gateway.platforms.base import (
    MessageType,
    _reply_anchor_for_event,
    _thread_metadata_for_source,
)
from plugins.platforms.feishu.adapter import FeishuAdapter


async def classify(*, chat_type: str, thread_id: str | None):
    adapter = FeishuAdapter.__new__(FeishuAdapter)
    adapter._extract_message_content = AsyncMock(
        return_value=("question", MessageType.TEXT, [], [], [])
    )
    adapter._fetch_message_text = AsyncMock(return_value="quoted answer")
    adapter.get_chat_info = AsyncMock(return_value={"name": "Canary Chat"})
    adapter._resolve_sender_profile = AsyncMock(
        return_value={
            "user_id": "ou_canary",
            "user_name": "Canary",
            "user_id_alt": None,
        }
    )
    resolved_chat_type = "dm" if chat_type == "p2p" else "group"
    adapter._resolve_source_chat_type = Mock(return_value=resolved_chat_type)
    adapter._resolve_channel_prompt = Mock(return_value=None)
    adapter.build_source = Mock(
        side_effect=lambda **kwargs: SimpleNamespace(
            platform="feishu",
            chat_type=kwargs["chat_type"],
            thread_id=kwargs["thread_id"],
        )
    )
    adapter._dispatch_inbound_event = AsyncMock()

    message = SimpleNamespace(
        chat_id="oc_canary",
        parent_id="om_quoted",
        upper_message_id=None,
        root_id="om_root",
        thread_id=thread_id,
    )
    await adapter._process_inbound_message(
        data=message,
        message=message,
        sender_id=SimpleNamespace(
            open_id="ou_canary",
            user_id=None,
            union_id=None,
        ),
        chat_type=chat_type,
        message_id="om_current",
    )
    return adapter._dispatch_inbound_event.await_args.args[0]


async def main() -> None:
    dm_quote = await classify(chat_type="p2p", thread_id="omt_stale_root")
    assert dm_quote.source.thread_id is None
    assert _reply_anchor_for_event(dm_quote) == "om_current"
    assert _thread_metadata_for_source(dm_quote.source, "om_current") is None
    assert dm_quote.reply_to_message_id == "om_quoted"
    assert dm_quote.reply_to_text == "quoted answer"

    # A persisted Session created by an older runtime can still carry a stale
    # Feishu DM thread_id even though new inbound classification is fixed.  The
    # shared outbound layer must defensively keep that Session in the main DM.
    stale_dm_source = SimpleNamespace(
        platform="feishu",
        chat_type="dm",
        thread_id="omt_persisted_stale_root",
    )
    stale_dm_event = SimpleNamespace(
        source=stale_dm_source,
        message_id="om_current_persisted",
        reply_to_message_id="om_quoted_persisted",
    )
    assert _thread_metadata_for_source(
        stale_dm_source, "om_current_persisted"
    ) is None
    assert _reply_anchor_for_event(stale_dm_event) == "om_current_persisted"

    group_quote = await classify(chat_type="group", thread_id=None)
    assert group_quote.source.thread_id is None
    assert _reply_anchor_for_event(group_quote) == "om_current"
    assert _thread_metadata_for_source(group_quote.source, "om_current") is None
    assert group_quote.reply_to_message_id == "om_quoted"

    real_topic = await classify(chat_type="group", thread_id="omt_real_topic")
    assert real_topic.source.thread_id == "omt_real_topic"
    assert _reply_anchor_for_event(real_topic) == "om_quoted"
    assert _thread_metadata_for_source(real_topic.source, "om_quoted") == {
        "thread_id": "omt_real_topic"
    }

    print("FEISHU_REPLY_ROUTING_CANARY=PASS")


if __name__ == "__main__":
    asyncio.run(main())
