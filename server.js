const express = require("express");

const app = express();
import axios from "axios";

app.use(express.static("public"));

app.get("/", async (req, res) => {
  let url = req.query.link;

  if (url) {
    let thiss = axios
      .get("https://" + url)
      .then(function (response) {
        res.json(response.data);
      })
      .catch(function (error) {
        console.log("Something went wrong " + error + " " + error.config.url);
        res.json("Something went wrong " + error + " " + error.config.url);
      });
  } else {
    res.send("No url given");
  }
});

const listener = app.listen(process.env.PORT, () => {
  console.log("Your app is listening on port " + listener.address().port);
});
