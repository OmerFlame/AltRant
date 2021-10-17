//let port = browser.runtime.connectNative("Open with AltRant");

/*while (true) {
    browser.runtime.sendNativeMessage("Open with AltRant", { message: window.location.href });
    
    setTimeout(function() {
        
    }, 3000);
}*/

function onGot(tabInfo) {
    let url = tabInfo.url;
    
    browser.runtime.sendNativeMessage("Open with AltRant", { message: url });
}

/*browser.tabs.query({currentWindow: true, active: true}).then((tabs) => {
    let tab = tabs[0]; // Safe to assume there will only be one result
    //console.log(tab.url);
    browser.runtime.sendNativeMessage("Open with AltRant", { message: tab.url });
}, console.error)*/

/*browser.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
    
    browser.tabs.getCurrent().then(function(tab) {
        browser.runtime.sendNativeMessage("Open with AltRant", { message: tab.url }, function(response) {
            //browser.tabs.update(undefined, { url: response.message });
            browser.tabs.sendMessage(tabs[0].id, response, function(responsetwo) {});
        });
        console.log("sending message");
    }, console.error);
});*/

/*port.onMessage.addListener(function(msg) {
    browser.tabs.query({active: true, currentWindow: true}).then((tabs) => {
        //while (true) {
        //    browser.tabs.sendMessage(tabs[0].id, msg, function(response) {});
        //}
        
        browser.tabs.update(undefined, { url: "https://google.com" });
    })
    //browser.runtime.sendMessage(msg);
})*/

//await port.postMessage({ message: "Test" });

browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    console.log("Received request: ", request);
    
    var finalResponse = null;
    /*browser.runtime.sendNativeMessage("Open with AltRant", { message: request.url }, function(response) {
        //sendResponse(response);
    });*/
    
    var sanitizedURL = request.url.substring("https://devrant.com".length);
    
    if (sanitizedURL.indexOf("/users/") > -1) {
        var username = sanitizedURL.substring("/users/".length);
        
        sendResponse({ message: "altrant://" + username });
    } else if (sanitizedURL.indexOf("/rants/") > -1) {
        var evenMoreSanitizedURL = sanitizedURL.substring("/rants/".length);
        var rantID = evenMoreSanitizedURL.replace(/\D/g,'');
        
        sendResponse({ message: "altrant://" + rantID });
    }
    
    //sendResponse({ message: "OH NO" });
});


/*browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    console.log("Received request: ", request);

    //if (request.greeting === "hello")
    //    sendResponse({ farewell: "goodbye" });
    var currentTab = null;
    browser.tabs.getCurrent().then(function(tab) {
        currentTab = tab;
    }, console.error);
    
    var finalResponse = null;
    browser.runtime.sendNativeMessage("Open with AltRant", { message: tab.url }, function(response) {
        finalResponse = response;
        //browser.tabs.update(undefined, { url: response.message });
        //browser.tabs.sendMessage(tabs[0].id, response, function(responsetwo) {});
    });
    
    sendResponse({ message: "TEST TEST TEST" });
});*/
