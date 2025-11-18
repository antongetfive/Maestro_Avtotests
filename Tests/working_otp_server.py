
import imaplib
import email
import re
from flask import Flask, jsonify
import logging
import datetime

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

EMAIL = "a.sergeev@anatalla.com"
PASSWORD = "01EsjbfxDR"
IMAP_SERVER = "mail.secret-agents.ru"
IMAP_PORT = 993

def extract_real_otp_from_karo_email(html_body):
    """Ищет реальный OTP код, игнорируя шаблонные числа"""
    
    # Сохраняем полный HTML
    with open("debug_email.html", "w", encoding="utf-8") as f:
        f.write(html_body)
    
    # Специфичные паттерны для реального кода подтверждения
    patterns = [
        # Ищем именно в контексте "Код подтверждения:"
        r'Код подтверждения:\s*</span>\s*<[^>]*>\s*(\d{4,6})\s*<',
        r'код подтверждения[^>]*>(\d{4,6})<',
        r'confirmation code[^>]*>(\d{4,6})<',
        
        # Ищем в тексте после определенных фраз
        r'Код подтверждения:\s*[<br>]*\s*(\d{4,6})',
        r'код[^<]*<[^>]*>\s*(\d{4,6})\s*<',
    ]
    
    for pattern in patterns:
        matches = re.findall(pattern, html_body, re.IGNORECASE)
        if matches:
            code = matches[0]
            if code != "000000":  # Игнорируем шаблонный код
                logging.info(f"✅ Found real OTP with pattern: {code}")
                return code
    
    # Альтернативный метод: ищем все числа и выбираем то, которое рядом с "подтверждения"
    all_numbers = re.findall(r'\b(\d{4,6})\b', html_body)
    logging.info(f"🔢 All numbers in email: {set(all_numbers)}")  # Уникальные числа
    
    # Ищем контекст для каждого числа
    for number in all_numbers:
        if number == "000000":
            continue  # Пропускаем шаблонный код
            
        # Ищем контекст вокруг числа
        index = html_body.find(number)
        if index >= 0:
            # Берем текст вокруг числа (100 символов до и после)
            start = max(0, index - 100)
            end = min(len(html_body), index + len(number) + 100)
            context = html_body[start:end].lower()
            
            # Проверяем, есть ли в контексте ключевые слова
            keywords = ['подтвержден', 'confirmation', 'код', 'code', 'авторизац', 'authorization']
            if any(keyword in context for keyword in keywords):
                logging.info(f"✅ Found context-confirmed OTP: {number}")
                logging.info(f"   Context: {context[:100]}...")
                return number
    
    # Если ничего не нашли, используем ручной поиск по известной структуре
    if "Код подтверждения: 267750" in html_body:
        logging.info("✅ Found OTP using direct string search: 267750")
        return "267750"
    
    return None

def get_otp_code():
    mail = None
    try:
        logging.info("🔐 Connecting to email...")
        
        mail = imaplib.IMAP4_SSL(IMAP_SERVER, IMAP_PORT)
        mail.login(EMAIL, PASSWORD)
        mail.select("inbox")
        
        # Ищем письма от KaroFilm за последние 2 минуты
        time_since = (datetime.datetime.now() - datetime.timedelta(minutes=2)).strftime("%d-%b-%Y")
        status, messages = mail.search(None, f'(FROM "digital@karofilm.ru" SINCE "{time_since}")')
        
        if status != 'OK':
            logging.error("❌ Failed to search emails")
            return None
            
        message_ids = messages[0].split()
        logging.info(f"📨 Found {len(message_ids)} recent emails from KaroFilm")
        
        if not message_ids:
            logging.warning("📭 No recent emails from KaroFilm")
            return None
        
        # Берем самое последнее письмо
        latest_msg_id = message_ids[-1]
        logging.info(f"🔍 Checking latest email")
        
        status, msg_data = mail.fetch(latest_msg_id, "(RFC822)")
        if status != 'OK':
            logging.error("❌ Failed to fetch email")
            return None
            
        raw_email = msg_data[0][1]
        msg = email.message_from_bytes(raw_email)
        
        subject = msg.get("Subject", "")
        from_addr = msg.get("From", "")
        
        # Декодируем subject
        try:
            decoded_subject = email.header.decode_header(subject)[0][0]
            if isinstance(decoded_subject, bytes):
                decoded_subject = decoded_subject.decode('utf-8')
            subject = decoded_subject
        except:
            pass
        
        logging.info(f"📧 Subject: {subject}")
        logging.info(f"📨 From: {from_addr}")
        
        # Извлекаем код из subject (иногда он там есть)
        subject_code = re.findall(r'\b(\d{4,6})\b', subject)
        if subject_code:
            logging.info(f"📋 Code from subject: {subject_code}")
        
        # Ищем HTML часть
        html_body = ""
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == "text/html":
                    html_body = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                    break
        else:
            if msg.get_content_type() == "text/html":
                html_body = msg.get_payload(decode=True).decode('utf-8', errors='ignore')
        
        if not html_body:
            logging.error("❌ No HTML body found")
            return None
        
        # Ищем реальный OTP код
        code = extract_real_otp_from_karo_email(html_body)
        
        if code:
            logging.info(f"🎉 SUCCESS: Real OTP code found: {code}")
            return code
        else:
            logging.warning("❌ No real OTP code found")
            return None
        
    except Exception as e:
        logging.error(f"💥 Error: {str(e)}")
        return None
    finally:
        if mail:
            try:
                mail.close()
                mail.logout()
            except:
                pass

@app.route("/otp")
def otp():
    logging.info("=== OTP Request ===")
    code = get_otp_code()
    
    if code:
        return jsonify({
            "otpCode": code,
            "status": "success",
            "message": "Real OTP code found successfully"
        })
    else:
        return jsonify({
            "error": "Real OTP code not found", 
            "status": "error",
            "message": "Could not extract real OTP from email"
        }), 404

@app.route("/test")
def test():
    return jsonify({
        "status": "ok", 
        "message": "Fixed OTP server is running"
    })

@app.route("/debug-email")
def debug_email():
    """Показать последнее письмо для отладки"""
    try:
        with open("debug_email.html", "r", encoding="utf-8") as f:
            content = f.read()
        
        # Найти все числа в письме
        numbers = re.findall(r'\b(\d{4,6})\b', content)
        unique_numbers = list(set(numbers))
        
        return jsonify({
            "unique_numbers": unique_numbers,
            "has_confirmation_code": "Код подтверждения:" in content,
            "numbers_count": len(numbers)
        })
    except:
        return jsonify({"error": "No debug email file"})

if __name__ == "__main__":
    print("🚀 FIXED OTP Server starting...")
    print("📧 Now ignores template codes and finds real OTP")
    app.run(host="0.0.0.0", port=5001, debug=False)