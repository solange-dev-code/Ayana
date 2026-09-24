from tests.conftest import client, register_user


def test_health():
    resp = client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_register_and_me():
    token = register_user(pseudo="Lyre", phone="90000001")
    me = client.get("/api/users/me", headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200
    body = me.json()
    assert body["pseudo"] == "Lyre"
    assert body["phone"] == "90000001"
    assert body["is_guest"] is False
    assert body["consent_accepted"] is True


def test_register_duplicate_phone():
    register_user(pseudo="Aa", phone="90000002")
    resp = client.post(
        "/api/auth/register",
        json={"pseudo": "Bb", "phone": "90000002", "password": "secret6", "consent": True},
    )
    assert resp.status_code == 409


def test_register_requires_consent():
    resp = client.post(
        "/api/auth/register",
        json={"pseudo": "Cc", "phone": "90000003", "password": "secret6", "consent": False},
    )
    assert resp.status_code == 400


def test_login_ok_and_wrong_password():
    register_user(pseudo="Dd", phone="90000004", password="secret6")
    ok = client.post(
        "/api/auth/login",
        data={"username": "90000004", "password": "secret6"},
    )
    assert ok.status_code == 200
    assert ok.json()["token_type"] == "bearer"

    bad = client.post(
        "/api/auth/login",
        data={"username": "90000004", "password": "mauvais"},
    )
    assert bad.status_code == 401


def test_guest_account():
    resp = client.post("/api/auth/guest")
    assert resp.status_code == 201
    body = resp.json()
    assert body["is_new_user"] is True
    assert body["user"]["is_guest"] is True
    assert body["user"]["phone"] is None

    me = client.get(
        "/api/users/me", headers={"Authorization": f"Bearer {body['access_token']}"}
    )
    assert me.status_code == 200
    assert me.json()["is_guest"] is True


def test_otp_flow_creates_account():
    import re

    phone = "90000005"
    req = client.post("/api/auth/otp/request", json={"phone": phone})
    assert req.status_code == 200
    assert "MODE DÉMO" in req.json()["detail"]
    match = re.search(r"code\s*:\s*(\d+)", req.json()["detail"])
    assert match, req.json()["detail"]
    code = match.group(1)

    verify = client.post("/api/auth/otp/verify", json={"phone": phone, "code": code})
    assert verify.status_code == 200
    body = verify.json()
    assert body["is_new_user"] is True
    assert body["user"]["phone"] == phone

    me = client.get(
        "/api/users/me", headers={"Authorization": f"Bearer {body['access_token']}"}
    )
    assert me.status_code == 200


def test_otp_wrong_code():
    client.post("/api/auth/otp/request", json={"phone": "90000006"})
    verify = client.post(
        "/api/auth/otp/verify", json={"phone": "90000006", "code": "000000"}
    )
    assert verify.status_code == 400


def test_update_profile_language_and_pseudo():
    token = register_user(pseudo="Zoe", phone="90000007")
    headers = {"Authorization": f"Bearer {token}"}

    upd = client.patch(
        "/api/users/me",
        headers=headers,
        json={"language": "ewe", "full_name": ""},
    )
    assert upd.status_code == 200
    body = upd.json()
    assert body["language"] == "ewe"


def test_unauthorized_access():
    resp = client.get("/api/users/me")
    assert resp.status_code == 401