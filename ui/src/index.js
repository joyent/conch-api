var m = require("mithril");
//var localStorage = require("localStorage");

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
            headers: {
                "Content-Type": "application/json"
            },
            url: "http://10.64.223.75:80/login",
            data: {user: Auth.username, password: Auth.password}
            //withCredentials: true
        }).then(function(data) {
            console.log("logged in successfully and got " + data.token);
            console.log(data);
            //localStorage.setItem("auth-token", data.token);
            //m.route.set("/racks");
        }).catch(function(error) {
            console.log("An error fired: ");
            console.log(error);
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
              "Login blah")]);
    }
}

var RackList = require("./views/RackList");

m.route(document.body, "/list", {
    "/list": {
        onmatch: function() {
            if (!localStorage.getItem("auth-token")) {
                return m.route.set("/login");
            }
            else {
                return RackList;
            }
        }
    },
    "/login": Login
});
