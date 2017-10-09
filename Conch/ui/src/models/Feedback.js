import m from "mithril";

const Feedback = {
    text: "",
    sendFeedback(subject, message, next) {
        return m
            .request({
                method: "POST",
                url: "/feedback",
                data: { subject, message },
            })
            .then(data => {
                next(data);
            })
            .catch(e => {
                console.log("An error fired: ");
                console.log(e);
            });
    },
    sendUserFeedback(text, next) {
        return this.sendFeedback("Conch User Feedback", text, next);
    },
};

export default Feedback;
