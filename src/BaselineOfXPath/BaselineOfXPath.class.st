Class {
	#name : #BaselineOfXPath,
	#superclass : #BaselineOf,
	#classVars : [
		'LastVersionLoad'
	],
	#category : #BaselineOfXPath
}

{ #category : #baselines }
BaselineOfXPath >> baseline: spec [
   <baseline>
	spec for: #'common' do: [
		spec
			baseline: 'XMLParser' with: [
				spec repository: 'github://feenkcom/XMLParser/src' ].
		spec 
			package: #'XPath-Core';
			package: #'XPath-Tests'
		].

]
