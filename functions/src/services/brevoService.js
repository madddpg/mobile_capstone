const axios = require("axios");
const { defineSecret, defineString } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const BREVO_API_KEY = defineString("BREVO_API_KEY");
const BREVO_SENDER_NAME = defineString("BREVO_SENDER_NAME", { default: "iConstruct" });
const BREVO_SENDER_EMAIL = defineString("BREVO_SENDER_EMAIL");

/**
 * Core function to send email via Brevo API
 */
async function sendBrevoEmail({ to, subject, htmlContent }) {
  try {
    const response = await axios.post(
      "https://api.brevo.com/v3/smtp/email",
      {
        sender: {
          name: BREVO_SENDER_NAME.value(),
          email: BREVO_SENDER_EMAIL.value(),
        },
        to: [{ email: to }],
        subject: subject,
        htmlContent: htmlContent,
      },
      {
        headers: {
          "api-key": BREVO_API_KEY.value(),
          "Content-Type": "application/json",
        },
      }
    );
    logger.info(`Email successfully sent to ${to}`, response.data);
    return response.data;
  } catch (error) {
    logger.error("Error sending email via Brevo", error.response?.data || error.message);
    throw new Error("Failed to send email.");
  }
}

exports.sendOtpEmail = async (email, otp) => {
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; text-align: center; color: #333;">
      <h2>Welcome to iConstruct!</h2>
      <p>Here is your 6-digit verification code:</p>
      <h1 style="letter-spacing: 5px; color: #0056b3;">${otp}</h1>
      <p>This code will expire in 5 minutes. Do not share it with anyone.</p>
    </div>
  `;
  return sendBrevoEmail({ to: email, subject: "Your iConstruct Verification Code", htmlContent });
};

exports.sendForgotPasswordEmail = async (email, resetToken) => {
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; color: #333;">
      <h2>Password Reset Request</h2>
      <p>We received a request to reset your password. Use the code below inside the app:</p>
      <h1 style="letter-spacing: 5px; color: #d9534f;">${resetToken}</h1>
      <p>If you did not request this, please ignore this email. The code expires in 15 minutes.</p>
    </div>
  `;
  return sendBrevoEmail({ to: email, subject: "iConstruct Password Reset", htmlContent });
};

exports.sendPasswordResetSuccessEmail = async (email) => {
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; color: #333;">
      <h2>Password Updated Successfully</h2>
      <p>Your iConstruct password has been successfully updated.</p>
    </div>
  `;
  return sendBrevoEmail({ to: email, subject: "Password Updated Successfully", htmlContent });
};

exports.sendWelcomeEmail = async (email) => {
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; color: #333;">
      <h2>Welcome to iConstruct!</h2>
      <p>Your account has been verified successfully. We're glad to have you aboard.</p>
    </div>
  `;
  return sendBrevoEmail({ to: email, subject: "Welcome to iConstruct!", htmlContent });
};