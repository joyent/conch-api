var m = require('mithril');
var t = require('i18n4v');
var Feedback = require('../models/Feedback');


var feedbackForm = {
    view: function() {
        return m(".feedback-form",
            feedbackForm.submitted ?
                  m(".text-center", t("Feedback submitted, thank you!"))
                : m("form.pure-form", [
                    m("legend", t("Send Feedback")),
                    m("fieldset.pure-group", [
                        m("textarea[required=true].pure-input-1", {
                            oninput: m.withAttr("value", function(v) { Feedback.text = v; }),
                            placeholder: t("Tell us something you would like us to fix or improve"),
                            value: Feedback.text
                        }),
                        m("button[type=submit].pure-button.pure-button-primary.pure-input-1", {
                            onclick: function(e) {
                                e.preventDefault();
                                Feedback.sendUserFeedback(Feedback.text, function() {
                                    feedbackForm.submitted = true;
                                    setTimeout(function() { location.reload(); }, 1600);
                                });
                            }
                        },
                            t("Send Feedback")
                        )
                    ])
                ])
        );
    }
};

module.exports = feedbackForm;
