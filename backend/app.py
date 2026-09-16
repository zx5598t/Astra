import json
import os
from typing import Any, Literal

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from openai import OpenAI
from pydantic import BaseModel, Field

load_dotenv()

CONTRACT_VERSION = "0.0.6"
MODEL = os.getenv("ASTRA_OPENAI_MODEL", "gpt-5.6-luna")
client = OpenAI()
app = FastAPI(title="ASTRA AI Gateway", version=CONTRACT_VERSION)

SocialAct = Literal["answer", "deflect", "accuse", "reassure", "interrupt", "challenge", "refuse"]
Emotion = Literal["calm", "uneasy", "angry", "afraid", "guarded", "warm", "cold"]
ClaimMode = Literal["truth", "lie", "speculation", "mistake"]


class NPCActionModel(BaseModel):
    social_act: SocialAct
    target_id: str = ""
    claim_refs: list[str] = Field(default_factory=list)
    claim_mode: ClaimMode = "truth"
    display_emotion: Emotion = "calm"
    relationship_delta: float = Field(default=0.0, ge=-0.12, le=0.12)
    utterance: str = Field(min_length=1, max_length=360)


class NPCRequest(BaseModel):
    contract_version: str
    provider: str = "openai_backend"
    npc: dict[str, Any]
    scene: dict[str, Any]
    allowed_fact_refs: list[str] = Field(default_factory=list)
    allowed_facts: dict[str, str] = Field(default_factory=dict)
    allowed_target_ids: list[str] = Field(default_factory=list)
    known_evidence: list[str] = Field(default_factory=list)
    relationships: dict[str, float] = Field(default_factory=dict)
    recent_turns: list[dict[str, Any]] = Field(default_factory=list)
    instruction: str = ""


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "contract_version": CONTRACT_VERSION, "model": MODEL}


@app.post("/npc/action")
def npc_action(req: NPCRequest) -> dict[str, Any]:
    if req.contract_version != CONTRACT_VERSION:
        raise HTTPException(status_code=409, detail="contract_version_mismatch")

    system_prompt = (
        "You are the performance layer for ASTRA, a Korean social-deduction RPG. "
        "Act only as the supplied NPC. The game engine owns truth. Never invent canonical events, "
        "roles, evidence, locations, vote outcomes, or numeric relationship changes. "
        "You may reference only allowed_facts and recent_turns supplied by the engine. "
        "If scene.situation is public_meeting, preserve the intent and target of the supplied rule-based event "
        "while rewriting it in the NPC's own voice. Do not reveal hidden roles. "
        "Keep the utterance natural, character-specific, concise, and normally in Korean. "
        "A lie may be strategic framing or denial, but must not introduce a new canonical fact."
    )
    safe_context = {
        "npc": req.npc,
        "scene": req.scene,
        "allowed_facts": req.allowed_facts,
        "allowed_target_ids": req.allowed_target_ids,
        "known_evidence": req.known_evidence,
        "relationships": req.relationships,
        "recent_turns": req.recent_turns[-10:],
    }

    try:
        response = client.responses.parse(
            model=MODEL,
            input=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": json.dumps(safe_context, ensure_ascii=False)},
            ],
            text_format=NPCActionModel,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"provider_error:{type(exc).__name__}") from exc

    parsed = response.output_parsed
    if parsed is None:
        raise HTTPException(status_code=502, detail="empty_structured_output")

    action = parsed.model_dump()
    action["claim_refs"] = [ref for ref in action["claim_refs"] if ref in req.allowed_fact_refs]
    if action["target_id"] and action["target_id"] not in req.allowed_target_ids:
        action["target_id"] = ""
    action["relationship_delta"] = max(-0.12, min(0.12, float(action["relationship_delta"])))

    return {
        "ok": True,
        "contract_version": CONTRACT_VERSION,
        **action,
    }
