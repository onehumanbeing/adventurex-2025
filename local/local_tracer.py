import json
import os
from uuid import UUID

from langchain.callbacks.base import BaseCallbackHandler
from langchain.schema import BaseMessage, LLMResult
from langchain_core.messages import convert_to_openai_messages


class LocalTracer(BaseCallbackHandler):
    _id_counter_map: dict[str, int] = {}
    _storage_path: str

    _run_logs: dict[str, str] = {}

    def __init__(self, storage_path: str):
        self._storage_path = os.path.abspath(storage_path)

    def on_chat_model_start(
        self,
        serialized: dict,
        message_lists: list[list[BaseMessage]],
        *,
        run_id: UUID,
        **kwargs,
    ):
        thread_id = kwargs["metadata"].get("thread_id", run_id)
        params: dict = kwargs["invocation_params"]
        for message_list in message_lists:
            chat_completion_params = params.copy()
            chat_completion_params["messages"] = convert_to_openai_messages(
                message_list
            )
            self._log_chat_completion(thread_id, run_id, chat_completion_params)

    def on_llm_end(
        self,
        response: LLMResult,
        *,
        run_id: UUID,
        **kwargs,
    ):
        message = response.generations[0][0].message
        converted_message = convert_to_openai_messages([message])[0]
        self._update_chat_completion_response(run_id, converted_message)

    def _log_chat_completion(self, thread_id: str, run_id: UUID, data: dict):
        key = f"{run_id}"
        log_id = self._next_log_id(thread_id)
        file_name = os.path.join(
            self._storage_path,
            f"{thread_id}/{log_id:03d}.json",
        )
        os.makedirs(os.path.dirname(file_name), exist_ok=True)
        self._run_logs[key] = file_name
        with open(file_name, "w") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f'> Saved in "{file_name}"')

    def _update_chat_completion_response(self, run_id: UUID, response_message: dict):
        key = f"{run_id}"
        file_name = self._run_logs[key]
        with open(file_name, "r") as f:
            existing_data = json.load(f)
        existing_data["messages"].append(response_message)
        with open(file_name, "w") as f:
            json.dump(existing_data, f, indent=2, ensure_ascii=False)

    def _next_log_id(self, thread_id: str) -> int:
        if thread_id not in self._id_counter_map:
            self._id_counter_map[thread_id] = 0
        self._id_counter_map[thread_id] += 1
        return self._id_counter_map[thread_id]
