# test_final.py
import urllib.request
import json
import time

def test_final():
    base_url = "http://127.0.0.1:5001"
    
    print("🧪 Testing Final OTP Server")
    print("⏳ Make sure you requested a new code in the app...")
    time.sleep(2)
    
    # Тест сервера
    try:
        response = urllib.request.urlopen(f"{base_url}/test", timeout=10)
        data = json.loads(response.read().decode())
        print(f"✅ Server: {data['message']}")
    except Exception as e:
        print(f"❌ Server test failed: {e}")
        return
    
    # Запрос OTP
    print("\n📨 Requesting OTP code...")
    try:
        response = urllib.request.urlopen(f"{base_url}/otp", timeout=30)
        data = json.loads(response.read().decode())
        print(f"🎉 SUCCESS: OTP code found!")
        print(f"🔢 Code: {data['otpCode']}")
        print(f"📋 Full response: {data}")
        
    except urllib.error.HTTPError as e:
        if e.code == 404:
            error_data = json.loads(e.read().decode())
            print(f"❌ OTP not found: {error_data['error']}")
            print("💡 Request a new code in the app and try again")
        else:
            print(f"❌ HTTP Error {e.code}: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_final()