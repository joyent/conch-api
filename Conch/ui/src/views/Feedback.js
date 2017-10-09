import m from "mithril";
import t from "i18n4v";
import Feedback from "../models/Feedback";
import Icons from "./component/Icons";

const feedbackForm = {
    view({ attrs }) {
        return m(
            ".feedback-form",
            m(
                "a.feedback-form-close",
                { onclick: () => (attrs.showFeedback = false) },
                Icons.ui.close
            ),
            feedbackForm.submitted
                ? m(".text-center", t("Feedback submitted"))
                : m("form.pure-form", [
                      m("legend", t("Send Feedback")),
                      m("fieldset.pure-group", [
                          m("textarea[required=true].pure-input-1", {
                              oninput: m.withAttr("value", v => {
                                  Feedback.text = v;
                              }),
                              placeholder: t("Feedback placeholder"),
                              value: Feedback.text,
                          }),
                          m(
                              "button[type=submit].pure-button.pure-button-primary.pure-input-1",
                              {
                                  onclick(e) {
                                      e.preventDefault();
                                      Feedback.sendUserFeedback(
                                          Feedback.text,
                                          () => {
                                              feedbackForm.submitted = true;
                                              setTimeout(() => {
                                                  location.reload();
                                              }, 1600);
                                          }
                                      );
                                  },
                              },
                              t("Submit Feedback")
                          ),
                      ]),
                  ])
        );
    },
};

export default feedbackForm;
