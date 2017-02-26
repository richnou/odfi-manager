$(function() {
	
	console.log("Starting RunFile...");
	localWeb.onPushData("StreamCreate",function(streamCreate) {
		
		console.log("Adding stream...");
		
		//-- parameters
		var streamPath = localWeb.decodeHTML(streamCreate.Name)
		
		//-- Get Table
		var streamTable = $("#streams-table");
		streamTable.parent().show();
		var streamTableBody = $("#streams-table tbody");
		
		//-- Create link
		var fileLink = "<a href=\"/odfi/file/view?path="+streamPath+"\" target='_blank'>"+streamPath+"</a>";
		
		//-- add Line
		streamTableBody.append("<tr><td>"+fileLink+"</td><td id=\""+streamCreate.ID+"-size\"></td></tr>");
		
	});
	
	localWeb.onPushData("StreamParameter",function(streamParameter) {
		
		console.log("Received parameter...");
		
		//-- parameters
		var streamId 	= localWeb.decodeHTML(streamParameter.ID)
		var pName 		= localWeb.decodeHTML(streamParameter.Name)
		var pValue	 	= localWeb.decodeHTML(streamParameter.Value)
		
		//-- Get Table
		var parameterHolder = $("#"+streamId+"-"+pName);
		if (parameterHolder) {
			parameterHolder.text(pValue);
		}
		
		
		
	});
	
});
