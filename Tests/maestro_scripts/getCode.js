console.log("🔥 JS STARTED");

const response = http.get("http://localhost:5001/otp");
console.log("➡️ Response status:", response.status);
console.log("➡️ Response body:", response.body);

const data = json(response.body);

if (!data.otpCode) {
  throw new Error("OTP not found in response");
}

// Возвращаем реальный OTP
output.otp = data.otpCode;
console.log("🔥 JS DONE. OTP:", output.otp);
