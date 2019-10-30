Class {
	#name : #BaselineOfXPath,
	#superclass : #BaselineOf,
	#classVars : [
		'LastVersionLoad'
	],
	#category : #BaselineOfXPath
}

{ #category : #baseline }
BaselineOfXPath >> baseline: spec [
	<baseline>
	spec for: #'common' do: [
		spec baseline: 'XMLParser' with: [
				spec repository: 'github://feenkcom/XMLParser:v0.6.1/src' ].
		spec 
			package: #'XPath-Core';
			package: #'XPath-Tests'. ].

]
