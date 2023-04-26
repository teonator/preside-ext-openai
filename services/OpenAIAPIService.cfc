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

			http url=apiUrl method=arguments.method result="apiResult" timeout=30 {
				httpparam type="header" name="Content-Type"  value="application/json";
				httpparam type="header" name="Authorization" value="Bearer #apiKey#";

				if ( StructCount( arguments.params ) ) {
					httpparam type="body" value="#SerializeJSON( arguments.params )#";
				}
			}
		} catch( any e ) {
			$raiseError( e );
		}

		return _processResult( apiResult );
	}

	public struct function listModels() {
		return this.request(
			  uri    = "models"
			, method = "GET"
		);
	}

	public struct function createCompletion(
		  required string  model
		,          string  prompt           = "\n\n"
		,          string  suffix           = NullValue()
		,          numeric maxTokens        = 16
		,          numeric temperature      = 1
		,          numeric topP             = 1
		,          numeric n                = 1
		,          boolean stream           = false
		,          numeric logprobs         = NullValue()
		,          boolean echo             = false
		,          string  stop             = NullValue()
		,          numeric presencePenalty  = 0
		,          numeric frequencyPenalty = 0
		,          numeric bestOf           = 1
	) {
		var params = {};

		for ( var key in arguments ) {
			StructAppend( params, { "#LCase( REReplace( key, "([a-z0-9])([A-Z])", "\1_\2", "ALL" ) )#"=arguments[ key ] } );
		}

		return this.request(
			  uri    = "completions"
			, method = "POST"
			, params = params
		);
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