require("dotenv").config();

const axios = require("axios").default;

const BREVO_API_KEY = process.env.BREVO_API_KEY;

async function sendBrevoEmail({ to, subject, htmlContent, textContent }) {
  if (!BREVO_API_KEY) {
    throw new Error("BREVO_API_KEY is missing in process.env");
  }

  try {
    const response = await axios.post(
      "https://api.brevo.com/v3/smtp/email",
      {
        sender: {
          name: "iConstruct",
          email: "ahmadpaguta2005@gmail.com",
        },
        to: [{ email: to }],
        subject,
        htmlContent,
        textContent,
      },
      {
        headers: {
          "api-key": BREVO_API_KEY,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
      }
    );

    return response.data;
  } catch (error) {
    console.error("Brevo send error message:", error.message);
    console.error("Brevo response status:", error.response?.status);
    console.error("Brevo response data:", error.response?.data);
    throw new Error(
      error.response?.data?.message ||
        error.message ||
        "Failed to send email."
    );
  }
}

exports.sendOtpEmail = async (email, otp) => {
  return sendBrevoEmail({
    to: email,
    subject: "Your iConstruct OTP Code",
    htmlContent: `<p>Your OTP code is <b>${otp}</b></p>`,
    textContent: `Your OTP code is ${otp}`,
  });
};