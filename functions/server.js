const { app } = require("./api");
require("dotenv").config();

const PORT = 5000;
const HOST = "0.0.0.0";
console.log("BREVO_API_KEY loaded:", !!process.env.BREVO_API_KEY);

app.listen(PORT, HOST, () => {
  console.log(`Local server running at http://${HOST}:${PORT}`);
  console.log(`Use on phone: http://192.168.1.5:${PORT}`);
});