from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import secrets

app = Flask(__name__)
CORS(app, supports_credentials=True)

# In-memory session token store: token -> user info
token_store = {}


def get_db_connection():
    conn = sqlite3.connect("walley.db")
    conn.row_factory = sqlite3.Row
    return conn


def get_user_from_token():
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header[7:]
        return token_store.get(token)
    return None


@app.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    email = data.get("email")
    password = data.get("password")
    name = data.get("name")
    if not email or not password or not name:
        return jsonify({"error": "Missing fields"}), 400
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM users WHERE email = ?", (email,))
    if cur.fetchone():
        return jsonify({"error": "Email already in use"}), 409
    hashed_pw = generate_password_hash(password)
    cur.execute(
        "INSERT INTO users (email, password, name, balance, savings) VALUES (?, ?, ?, ?, ?)",
        (email, hashed_pw, name, 0, 0),
    )
    conn.commit()
    conn.close()
    return jsonify({"message": "User registered successfully"})


@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    email = data.get("email")
    password = data.get("password")
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM users WHERE email = ?", (email,))
    user = cur.fetchone()
    conn.close()
    if user and check_password_hash(user["password"], password):
        token = secrets.token_urlsafe(32)
        user_info = {"email": user["email"], "name": user["name"], "id": user["id"]}
        token_store[token] = user_info
        return jsonify(
            {
                "message": "Login successful",
                "name": user["name"],
                "email": user["email"],
                "token": token,
            }
        )
    return jsonify({"error": "Invalid credentials"}), 401


@app.route("/logout", methods=["POST"])
def logout():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    # Remove token from store
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header[7:]
        token_store.pop(token, None)
    return jsonify({"message": "Logged out"})


@app.route("/session/user", methods=["GET"])
def get_session_user():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    return jsonify(user)


@app.route("/user", methods=["GET"])
def get_user():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    email = request.args.get("email") or user["email"]
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM users WHERE email = ?", (email,))
    user = cur.fetchone()
    if not user:
        conn.close()
        return jsonify({"error": "User not found"}), 404
    cur.execute("SELECT * FROM transactions WHERE user_email = ? ORDER BY date", (email,))
    transactions = [dict(row) for row in cur.fetchall()]
    conn.close()
    user_data = dict(user)
    user_data["spendingHistory"] = transactions
    return jsonify(user_data)


@app.route("/user/update", methods=["POST"])
def update_user():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    data = request.get_json()
    email = data.get("email")
    if not email:
        return jsonify({"error": "Missing email"}), 400
    fields = {k: v for k, v in data.items() if k != "email"}
    if not fields:
        return jsonify({"error": "No fields to update"}), 400
    conn = get_db_connection()
    cur = conn.cursor()
    for field, value in fields.items():
        if field in ["balance", "savings", "name"]:
            cur.execute(f"UPDATE users SET {field} = ? WHERE email = ?", (value, email))
    conn.commit()
    conn.close()
    return jsonify({"message": "User updated successfully"})


@app.route("/transaction/add", methods=["POST"])
def add_transaction():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    data = request.get_json()
    email = data.get("email")
    amount = data.get("amount")
    category = data.get("category")
    notes = data.get("notes", "")
    date = data.get("date", datetime.now().isoformat())
    if not email or amount is None or not category:
        return jsonify({"error": "Missing fields"}), 400
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO transactions (user_email, amount, category, notes, date) VALUES (?, ?, ?, ?, ?)",
        (email, amount, category, notes, date),
    )
    cur.execute("UPDATE users SET balance = balance + ? WHERE email = ?", (amount, email))
    conn.commit()
    conn.close()
    return jsonify({"message": "Transaction added successfully"})


@app.route("/transaction/history", methods=["GET"])
def transaction_history():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    email = user["email"]
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM transactions WHERE user_email = ? ORDER BY date", (email,))
    transactions = [dict(row) for row in cur.fetchall()]
    conn.close()
    return jsonify({"transactions": transactions})


@app.route("/user/delete", methods=["POST"])
def delete_user():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    data = request.get_json()
    email = data.get("email")
    if not email:
        return jsonify({"error": "Missing email"}), 400
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM transactions WHERE user_email = ?", (email,))
    cur.execute("DELETE FROM users WHERE email = ?", (email,))
    conn.commit()
    conn.close()
    return jsonify({"message": "User and their transactions deleted"})


@app.route("/transaction/delete", methods=["POST"])
def delete_transaction():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    data = request.get_json()
    tid = data.get("id")
    if not tid:
        return jsonify({"error": "Missing transaction id"}), 400
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM transactions WHERE id = ?", (tid,))
    conn.commit()
    conn.close()
    return jsonify({"message": "Transaction deleted"})


@app.route("/transaction/update", methods=["POST"])
def update_transaction():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    data = request.get_json()
    tid = data.get("id")
    fields = {k: v for k, v in data.items() if k != "id"}
    if not tid or not fields:
        return jsonify({"error": "Missing transaction id or fields"}), 400
    conn = get_db_connection()
    cur = conn.cursor()
    for field, value in fields.items():
        if field in ["amount", "category", "notes", "date"]:
            cur.execute(f"UPDATE transactions SET {field} = ? WHERE id = ?", (value, tid))
    conn.commit()
    conn.close()
    return jsonify({"message": "Transaction updated"})


@app.route("/transaction/get", methods=["GET"])
def get_transaction():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    tid = request.args.get("id")
    if not tid:
        return jsonify({"error": "Missing transaction id"}), 400
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM transactions WHERE id = ?", (tid,))
    transaction = cur.fetchone()
    conn.close()
    if not transaction:
        return jsonify({"error": "Transaction not found"}), 404
    return jsonify(dict(transaction))


@app.route("/user/get_by_id", methods=["GET"])
def get_user_by_id():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    uid = request.args.get("id")
    if not uid:
        return jsonify({"error": "Missing user id"}), 400
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM users WHERE id = ?", (uid,))
    user = cur.fetchone()
    conn.close()
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(dict(user))


@app.route("/summary", methods=["GET"])
def get_summary():
    user = get_user_from_token()
    if not user:
        return jsonify({"error": "Not logged in"}), 401
    email = user["email"]
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT SUM(amount) as total_spent FROM transactions WHERE user_email = ? AND amount < 0",
        (email,),
    )
    total_spent = cur.fetchone()["total_spent"] or 0
    cur.execute(
        "SELECT SUM(amount) as total_deposit FROM transactions WHERE user_email = ? AND amount > 0",
        (email,),
    )
    total_deposit = cur.fetchone()["total_deposit"] or 0
    cur.execute("SELECT AVG(amount) as avg_amount FROM transactions WHERE user_email = ?", (email,))
    avg_amount = cur.fetchone()["avg_amount"] or 0
    cur.execute("SELECT COUNT(*) as count FROM transactions WHERE user_email = ?", (email,))
    count = cur.fetchone()["count"] or 0
    conn.close()
    return jsonify(
        {
            "total_spent": total_spent,
            "total_deposit": total_deposit,
            "avg_amount": avg_amount,
            "transaction_count": count,
        }
    )


if __name__ == "__main__":
    conn = get_db_connection()
    conn.execute(
        """CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        balance INTEGER DEFAULT 0,
        savings INTEGER DEFAULT 0
    )"""
    )
    conn.execute(
        """CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        notes TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY(user_email) REFERENCES users(email)
    )"""
    )
    conn.commit()
    conn.close()
    app.run(debug=True)
