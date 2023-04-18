/**
 * @singleton      true
 * @presideService true
 */
component {

	public any function init() {
		return this;
	}

	public any function request(
		  required string uri
		,          struct params  = {}
		,          string body    = ""
		,          string method  = "GET"
		,          string version = "1"
	) {
		var apiUrl    = "https://api.openai.com/v#arguments.version#/" & arguments.uri
		var apiResult = StructNew();
		var apiKey    = $getPresideSetting( "openai", "apiKey", "" );
		var apiParams = "";

		try {
			if ( !Len( Trim( apiKey ) ) ) {
				Throw( "Open API key is required.", "openai.api.key.required" );
			}

			for ( var key in arguments.params ) {
				apiParams = ListAppend( apiParams, "#key#=#arguments.params[ key ]#", "&" );
			}

			if ( Len( Trim( apiParams ) ) ) {
				apiUrl = "#apiUrl#?#apiParams#";
			}

			http url=apiUrl method=arguments.method result="apiResult" timeout=30 {
				httpparam type="header" name="Content-Type"  value="application/json";
				httpparam type="header" name="Authorization" value="Bearer #apiKey#";

				if ( Len( Trim( arguments.body ) ) ) {
					httpparam type="body" value=arguments.body;
				}
			}
		} catch( any e ) {
			$raiseError( e );
		}

		return _processResult( apiResult );
	}

	private struct function _processResult( required struct result ) {
		var processedResult = StructNew();
		var content         = result.fileContent ?: "";

		try {
			if( !IsJson( content ) ) {
				var errorDetail = result.errordetail ?: "";

				Throw( "Unexpected response from API call: #errorDetail#", "openai.api.response.bad", content );
			}

			processedResult = DeserializeJSON( content );
		} catch( any e ) {
			$raiseError( e );
		}

		return processedResult;
	}

}