import httpx

def run():
    print("Registering new designer...")
    resp = httpx.post("http://localhost:5000/api/auth/register", json={
        "name": "Test Designer",
        "email": "test.designer@stylesync.lk",
        "password": "password",
        "confirmPassword": "password",
        "role": "Designer"
    }, timeout=10.0)
    
    if resp.status_code not in (201, 200):
        print(f"Failed to register: {resp.status_code} - {resp.text}")
        # Might already exist
    else:
        print("Successfully registered test.designer@stylesync.lk with password 'password'")

if __name__ == "__main__":
    run()
