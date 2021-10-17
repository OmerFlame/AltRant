/*browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    console.log("Received request: ", request);
});*/

browser.runtime.sendMessage({ url: window.location.href }).then((response) => {
    console.log("Received response: ", response);
    window.location.href = response.message;
});

browser.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    console.log(request.message);
    //window.location.href = request.message;
    window.location.href = "https://google.com";
})

/*browser.tabs.onUpdated.addListener(function(tabID, changeInfo, tab) {
    browser.tabs.getSelected(null, function(tab) {
        browser.runtime.sendMessage({ url: window.location.href }).then((response) => {
            console.log("Received response: ", response);
        });
    })
})*/
