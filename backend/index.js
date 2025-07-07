const express = require("express");
const cors = require("cors");
const Razorpay = require("razorpay");
const bodyParser = require("body-parser");

const app = express();
app.use(cors());
app.use(bodyParser.json());

const razorpay = new Razorpay({
  key_id: "rzp_live_Y7TfZS3eA2vI0U",
  key_secret: "KMJ7t7gAlgTbNCMMw1drIbWL",
});

app.post("/create-order", async (req, res) => {
  const options = {
    amount: req.body.amount * 100, // amount in the smallest currency unit
    currency: "INR",
    receipt: req.body.receipt, // Use dynamic receipt from frontend
  };

  try {
    const order = await razorpay.orders.create(options);
    res.json(order);
  } catch (err) {
    res.status(500).send("Something went wrong!");
  }
});

app.listen(5000, () => {
  console.log("Backend server running on http://localhost:5000");
});