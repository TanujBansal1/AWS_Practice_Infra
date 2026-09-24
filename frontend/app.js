const API_BASE_URL = window.API_BASE_URL;

const listEl = document.getElementById("todo-list");
const errorEl = document.getElementById("error");
const formEl = document.getElementById("new-todo-form");
const titleInput = document.getElementById("new-todo-title");

function showError(message) {
  errorEl.textContent = message;
  errorEl.hidden = false;
}

function clearError() {
  errorEl.hidden = true;
}

async function fetchTodos() {
  clearError();
  try {
    const res = await fetch(`${API_BASE_URL}/todos`);
    if (!res.ok) throw new Error(`API returned ${res.status}`);
    renderTodos(await res.json());
  } catch (err) {
    showError(`Failed to load todos: ${err.message}`);
  }
}

function renderTodos(todos) {
  listEl.innerHTML = "";
  for (const todo of todos) {
    const li = document.createElement("li");
    if (todo.done) li.classList.add("done");

    const span = document.createElement("span");
    span.textContent = todo.title;
    li.appendChild(span);

    const deleteBtn = document.createElement("button");
    deleteBtn.className = "delete-btn";
    deleteBtn.textContent = "\u2715";
    deleteBtn.addEventListener("click", () => deleteTodo(todo.id));
    li.appendChild(deleteBtn);

    listEl.appendChild(li);
  }
}

async function createTodo(title) {
  clearError();
  try {
    const res = await fetch(`${API_BASE_URL}/todos`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, done: false }),
    });
    if (!res.ok) throw new Error(`API returned ${res.status}`);
    await fetchTodos();
  } catch (err) {
    showError(`Failed to create todo: ${err.message}`);
  }
}

async function deleteTodo(id) {
  clearError();
  try {
    const res = await fetch(`${API_BASE_URL}/todos/${id}`, { method: "DELETE" });
    if (!res.ok && res.status !== 204) throw new Error(`API returned ${res.status}`);
    await fetchTodos();
  } catch (err) {
    showError(`Failed to delete todo: ${err.message}`);
  }
}

formEl.addEventListener("submit", (event) => {
  event.preventDefault();
  const title = titleInput.value.trim();
  if (!title) return;
  titleInput.value = "";
  createTodo(title);
});

fetchTodos();
