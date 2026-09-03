"""Runtime canary for silent-by-default automatic compaction on chat surfaces."""

from agent.conversation_compression import COMPACTION_DONE_STATUS
import gateway.run as gateway_run


CHAT_PLATFORMS = ("feishu", "telegram", "slack")
RAW_PLATFORMS = ("local", "api_server", "webhook")


def main() -> None:
    original_loader = gateway_run._load_gateway_config
    try:
        gateway_run._load_gateway_config = lambda: {}
        for platform in CHAT_PLATFORMS:
            assert (
                gateway_run._prepare_gateway_status_message(
                    platform,
                    "compacted",
                    COMPACTION_DONE_STATUS,
                )
                is None
            )

        gateway_run._load_gateway_config = lambda: {
            "compression": {"progress_notices": True}
        }
        for platform in CHAT_PLATFORMS:
            assert gateway_run._prepare_gateway_status_message(
                platform,
                "compacted",
                COMPACTION_DONE_STATUS,
            ) == COMPACTION_DONE_STATUS

        for platform in RAW_PLATFORMS:
            assert gateway_run._prepare_gateway_status_message(
                platform,
                "compacted",
                COMPACTION_DONE_STATUS,
            ) == COMPACTION_DONE_STATUS

        gateway_run._load_gateway_config = lambda: {}
        failure = "⚠ Compression aborted: auth failure. No messages were dropped."
        assert gateway_run._prepare_gateway_status_message(
            "feishu",
            "warn",
            failure,
        ) == failure
        assert gateway_run._sanitize_gateway_final_response(
            "feishu",
            "在的，Kane。怎么了？",
        ) == "在的，Kane。怎么了？"
    finally:
        gateway_run._load_gateway_config = original_loader

    print("PASS: automatic compaction stays silent on chat surfaces")


if __name__ == "__main__":
    main()
