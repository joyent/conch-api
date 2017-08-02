var m = require("mithril");

var Auth = {
    username: "",
    password: "",

    setUsername: function(value) {
        Auth.username = value;
    },
    setPassword: function(value) {
        Auth.password = value;
    },
    login: function() {
        m.request({
            method: "POST",
            url: "http://localhost:5000/login",
            data: {user: Auth.username, password: Auth.password}
        }).then(function(data) {
            console.log("logged in successfully and got ");
            console.log(data);
            m.route.set("/racks");
        }).catch(function(e) {
            console.log("An error fired: ");
            console.log(e);
        });
    }
}

var Login = {
    view: function() {
        return m("form", [
            m("input[type=text]", {
                oninput: m.withAttr("value", Auth.setUsername),
                value: Auth.username}),
            m("input[type=password]", {
                oninput: m.withAttr("value", Auth.setPassword),
                value: Auth.password}),
            m("button[type=button]", {
                onclick: Auth.login},
              "Login")]);
    }
};



var RackList = require("./views/RackList");
var Layout = require("./views/Layout");

m.route(document.body, "/racks", {
    "/racks": {
        render: function() {
            return m(Layout, m(RackList));
        }
    },
    "/login": Login
});
