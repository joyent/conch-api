var m = require("mithril");

var Feedback = {
    text: "",
    sendFeedback: function(subject, message, next) {
        return m.request({
            method: "POST",
            url: "/feedback",
            data: {subject: subject, message: message}
        }).then(function(data) {
            next(data);
        }).catch(function(e) {
            console.log("An error fired: ");
            console.log(e);
        });
    },
    sendUserFeedback: function(text, next) {
        return this.sendFeedback("Conch User Feedback", text, next);
    }
};

module.exports = Feedback;
