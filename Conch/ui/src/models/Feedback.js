var m = require("mithril");

var Feedback = {
    text: "",
    sendUserFeedback: function(text, next) {
        return m.request({
            method: "POST",
            url: "/feedback",
            data: {feedback: text}
        }).then(function(data) {
            next(data);
        }).catch(function(e) {
            console.log("An error fired: ");
            console.log(e);
        });
    }
};

module.exports = Feedback;
