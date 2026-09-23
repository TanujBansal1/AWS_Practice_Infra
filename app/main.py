import os
from typing import Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

app = FastAPI(title="Todo API")

# DB connection is built lazily (only when a /todos route runs a query), not
# at import/startup time - this keeps /health independent of DB reachability
# so ECS health checks pass even before RDS exists or if the DB is briefly
# unavailable.
_engine = None


def get_engine():
    global _engine
    if _engine is None:
        db_host = os.environ["DB_HOST"]
        db_port = os.environ.get("DB_PORT", "5432")
        db_name = os.environ["DB_NAME"]
        db_user = os.environ["DB_USER"]
        db_password = os.environ["DB_PASSWORD"]
        url = f"postgresql+psycopg2://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
        _engine = create_engine(url, pool_pre_ping=True)
        with _engine.begin() as conn:
            conn.execute(
                text(
                    "CREATE TABLE IF NOT EXISTS todos ("
                    "id SERIAL PRIMARY KEY, "
                    "title TEXT NOT NULL, "
                    "done BOOLEAN NOT NULL DEFAULT FALSE)"
                )
            )
    return _engine


class TodoCreate(BaseModel):
    title: str
    done: bool = False


class Todo(BaseModel):
    id: int
    title: str
    done: bool


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/todos", response_model=list[Todo])
def list_todos():
    try:
        engine = get_engine()
        with engine.connect() as conn:
            rows = conn.execute(text("SELECT id, title, done FROM todos ORDER BY id")).fetchall()
        return [Todo(id=r.id, title=r.title, done=r.done) for r in rows]
    except (OperationalError, KeyError) as e:
        raise HTTPException(status_code=503, detail=f"database unavailable: {e}")


@app.post("/todos", response_model=Todo, status_code=201)
def create_todo(todo: TodoCreate):
    try:
        engine = get_engine()
        with engine.begin() as conn:
            row = conn.execute(
                text("INSERT INTO todos (title, done) VALUES (:title, :done) RETURNING id, title, done"),
                {"title": todo.title, "done": todo.done},
            ).fetchone()
        return Todo(id=row.id, title=row.title, done=row.done)
    except (OperationalError, KeyError) as e:
        raise HTTPException(status_code=503, detail=f"database unavailable: {e}")


@app.delete("/todos/{todo_id}", status_code=204)
def delete_todo(todo_id: int):
    try:
        engine = get_engine()
        with engine.begin() as conn:
            result = conn.execute(text("DELETE FROM todos WHERE id = :id"), {"id": todo_id})
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="todo not found")
    except (OperationalError, KeyError) as e:
        raise HTTPException(status_code=503, detail=f"database unavailable: {e}")
