# test_fixed.py
import urllib.request
import json

def test_fixed():
    base_url = "http://127.0.0.1:5001"
    
    print("🧪 Testing Fixed OTP Server")
    
    # Тест сервера
    try:
        response = urllib.request.urlopen(f"{base_url}/test", timeout=10)
        data = json.loads(response.read().decode())
        print(f"✅ Server: {data['message']}")
    except Exception as e:
        print(f"❌ Server test failed: {e}")
        return
    
    # Проверка отладки
    try:
        response = urllib.request.urlopen(f"{base_url}/debug-email", timeout=10)
        debug_data = json.loads(response.read().decode())
        print(f"📊 Debug info: {debug_data}")
    except Exception as e:
        print(f"⚠️ Debug check failed: {e}")
    
    # Запрос OTP
    print("\n📨 Requesting OTP code...")
    try:
        response = urllib.request.urlopen(f"{base_url}/otp", timeout=30)
        data = json.loads(response.read().decode())
        print(f"🎉 SUCCESS: OTP code found!")
        print(f"🔢 Code: {data['otpCode']}")
        
        # Проверяем что это не шаблонный код
        if data['otpCode'] == '000000':
            print("⚠️  WARNING: Still getting template code 000000")
        else:
            print("✅ SUCCESS: Got real OTP code!")
            
    except urllib.error.HTTPError as e:
        if e.code == 404:
            error_data = json.loads(e.read().decode())
            print(f"❌ OTP not found: {error_data['error']}")
        else:
            print(f"❌ HTTP Error {e.code}: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_fixed()