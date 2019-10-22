"
An XPathContext controls evaluation of XPath expressions. Contexts have a function library, variable bindings, and namespace mappings.

By default, qualified name tests like 'prefix:name' and wildcard tests like 'prefix:*' will match against the prefix directly. This isn't like the standard, where prefixes in node tests must be declared in the context before evaluation and the namespace they're bound to is matched against the (non-default) namespace of the node, but it's easier to use.

To get standard behavior, just declare at least one prefix in the context before evaluation (then every prefix must be declared in the context and the namespace URIs are matched instead of the literal prefixes).
"
Class {
	#name : #XPathContext,
	#superclass : #Object,
	#instVars : [
		'variables',
		'namespaceScope',
		'functions'
	],
	#classInstVars : [
		'defaultFunctions'
	],
	#category : #'XPath-Core'
}

{ #category : #accessing }
XPathContext class >> defaultFunctions [
	^ defaultFunctions
		ifNil: [defaultFunctions := XPathFunctionSet default]
]

{ #category : #accessing }
XPathContext class >> defaultFunctions: aFunctionSetOrNil [
	"can be used to specify a custom default function set"

	defaultFunctions := aFunctionSetOrNil
]

{ #category : #'instance creation' }
XPathContext class >> for: aPath in: aDocument [
	| context |
	context := self new.
	context path: aPath;
			root: aDocument.
	^context
]

{ #category : #'instance creation' }
XPathContext class >> functions: aFunctionSet [
	^ self new functions: aFunctionSet
]

{ #category : #'class initialization' }
XPathContext class >> initialize [
	"self initialize"

	self defaultFunctions: nil.
]

{ #category : #'instance creation' }
XPathContext class >> namespaces: anAssociationCollection [
	^ self new declareNamespaces: anAssociationCollection
]

{ #category : #'instance creation' }
XPathContext class >> new [
	^super new initialize.
]

{ #category : #'instance creation' }
XPathContext class >> variables: anAssociationCollection [
	^ self new variables: anAssociationCollection
]

{ #category : #'instance creation' }
XPathContext class >> variables: aVariableAssociationCollection namespaces: aNamepsaceAssociationCollection [
	^ self new
		variables: aVariableAssociationCollection;
		declareNamespaces: aNamepsaceAssociationCollection
]

{ #category : #'instance creation' }
XPathContext class >> variables: aVariableAssociationCollection namespaces: aNamepsaceAssociationCollection functions: aFunctionSet [
	^ self new
		variables: aVariableAssociationCollection;
		declareNamespaces: aNamepsaceAssociationCollection;
		functions: aFunctionSet
]

{ #category : #adding }
XPathContext >> addFunction: aFunction [
	"use copy-on-write so the default function set isn't modified"
	^ self copiedFunctions add: aFunction
]

{ #category : #instructions }
XPathContext >> andAttributes: namesCollection [
	"Look up an attribute"
	| allAttributes |
	
	allAttributes := OrderedCollection new: stack size.
	self pop do:
		[:element | 
			| attributes |
			attributes := element attributes keys asSet.
			( attributes = namesCollection asSet )
				ifTrue: [ allAttributes add: element attributes ] ].
	self push: ( allAttributes collect: [: each | each values ] )
]

{ #category : #instructions }
XPathContext >> at: nameIndex [ 
	| name values attribute |
	name := path literalAt: nameIndex.
	values := OrderedCollection new.
	name = '*'
		ifTrue: [self pop
				do: [:attributes | values addAll: attributes values]]
		ifFalse: [self pop
				do: [:attributes | 
					attributes at: name ifPresent: [:value | attribute := value. values add: attribute].
					]].
	self push: values
]

{ #category : #instructions }
XPathContext >> attribute: name [
	"Look up an attribute"
	| allAttributes values attribute |
	allAttributes := OrderedCollection new.
	self pop do:
		[:element | allAttributes add: element attributes].
	values := OrderedCollection new.
	name = '*'
		ifTrue: [allAttributes
				do: [:attributes | values addAll: attributes values]]
		ifFalse: [allAttributes
				do: [:attributes | 
					attributes at: name ifPresent: [:value | attribute := value. values add: attribute].
					]].
	self push: values
]

{ #category : #private }
XPathContext >> attributeTestForPrefix: aPrefix [
	self hasNamespaces
		ifTrue: [
			^ XPathAttributeNodeTestForNamespaceURI namespaceURI:
				(self resolvePrefixReference: aPrefix)]
		ifFalse: [
			^ XPathAttributeNodeTestForPrefix prefix: aPrefix]
]

{ #category : #private }
XPathContext >> attributeTestForPrefix: aPrefix localName: aLocalName [
	self hasNamespaces
		ifTrue: [
			^ XPathAttributeNodeTestForNamespaceURIAndLocalName
				namespaceURI: (self resolvePrefixReference: aPrefix)
				localName: aLocalName]
		ifFalse: [
			^ XPathAttributeNodeTestForName name:
				(aLocalName qualifyWithXMLPrefix: aPrefix)]
]

{ #category : #instructions }
XPathContext >> attributes [
	"Push the attributes"
	| allAttributes |
	"Processor activeProcess debugWithTitle: 'Trying out the attributes stuff'."
	allAttributes := OrderedCollection new.
	self pop do:
		[:element | allAttributes add: element attributes].
		"[:element | element attributes associationsDo: [:assoc | allAttributes add: assoc]]. "
	self push: allAttributes.
]

{ #category : #instructions }
XPathContext >> both: arg1 and: arg2 [
	^ self
]

{ #category : #private }
XPathContext >> copiedFunctions [
	"used to implement copy-on-write for functions"
	^ functions := self functions copy
]

{ #category : #functions }
XPathContext >> count [
	self
		push: (Array with: self pop size)
]

{ #category : #namespacing }
XPathContext >> declareNamespaces: anAssociationCollection [
	self namespaceScope mapPrefixesAndURIs: anAssociationCollection
]

{ #category : #namespacing }
XPathContext >> declarePrefix: aPrefix uri: aURI [
	self namespaceScope
		mapPrefix: aPrefix
		to: aURI
]

{ #category : #instructions }
XPathContext >> descendants [
	"Gather all of the descendant nodes"
	"Processor activeProcess debugWithTitle: 'Checking descendants code'."
	| parents children allDescendants |
	parents := OrderedCollection withAll: self pop.
	"allDescendants := OrderedCollection new."
	allDescendants := OrderedCollection withAll: parents.
	children := OrderedCollection new.
	[parents isEmpty]
		whileFalse: [parents
				do: [:parent | parent isElement
						ifTrue: [children addAll: parent elements]].
			allDescendants addAll: children.
			parents := children.
			children := OrderedCollection new].
	self push: allDescendants
]

{ #category : #instructions }
XPathContext >> either: arg1 or: arg2 [
]

{ #category : #instructions }
XPathContext >> element: elemName [
	| children matches |
	children := OrderedCollection new.
	self root name = elemName
		ifTrue: [ self parent pop do: [ : element | children addAll: (element elements select: #isElement) ] ]
		ifFalse: [ self pop do: [ : element | 
					element isElement
						ifTrue: [ children addAll: (element elements select: #isElement) ] ] ].
	matches := (children select: [ : element | element name = elemName or: [ elemName = '*' ] ]).
	self push: matches.
]

{ #category : #private }
XPathContext >> elementTestForPrefix: aPrefix [
	self hasNamespaces
		ifTrue: [
			^ XPathElementNodeTestForNamespaceURI namespaceURI:
				(self resolvePrefixReference: aPrefix)]
		ifFalse: [
			^ XPathElementNodeTestForPrefix prefix: aPrefix]
]

{ #category : #private }
XPathContext >> elementTestForPrefix: aPrefix localName: aLocalName [
	self hasNamespaces
		ifTrue: [
			^ XPathElementNodeTestForNamespaceURIAndLocalName
				namespaceURI: (self resolvePrefixReference: aPrefix)
				localName: aLocalName]
		ifFalse: [
			^ XPathElementNodeTestForName name:
				(aLocalName qualifyWithXMLPrefix: aPrefix)]
]

{ #category : #instructions }
XPathContext >> elements [
	| children |
	children := OrderedCollection new.
	self pop
		do: [:element | "[:element | children addAll: element elements]."
			element isElement
				ifTrue: [children
						addAll: (element elements
								select: [:element2 | element2 isElement])]].
	self push: children
]

{ #category : #private }
XPathContext >> errorUndeclaredFunction: aFunctionName [
	XPathUndeclaredFunctionException
		formatSignal: 'Undeclared function {1}()'
		with: aFunctionName
]

{ #category : #private }
XPathContext >> errorUndeclaredPrefix: aPrefix [
	XPathUndeclaredPrefixException
		formatSignal: 'Prefix "{1}" was not declared in the XPath context'
		with: aPrefix
]

{ #category : #private }
XPathContext >> errorUndeclaredVariable: aVariableName [
	XPathUndeclaredVariableException
		formatSignal: 'Undeclared variable reference ${1}'
		with: aVariableName
]

{ #category : #instructions }
XPathContext >> finish [
	done := true.
	results := self pop.
	
]

{ #category : #accessing }
XPathContext >> functionNamed: aFunctionName [
	^ self functions functionNamed: aFunctionName
]

{ #category : #accessing }
XPathContext >> functionNamed: aFunctionName ifAbsent: aBlock [
	^ self functions 
		functionNamed: aFunctionName
		ifAbsent: aBlock
]

{ #category : #private }
XPathContext >> functions [
	"the default function set won't be directly modified because the add/remove
	methods use copy-on-write semantics"
	^ functions ifNil: [functions := self class defaultFunctions]
]

{ #category : #accessing }
XPathContext >> functions: aFunctionSet [
	"will only be modified by copy-on-write"
	functions := aFunctionSet asXPathFunctionSet
]

{ #category : #testing }
XPathContext >> hasFunctions [
	^ self functions notEmpty
]

{ #category : #testing }
XPathContext >> hasNamespaces [
	^ namespaceScope notNil
		and: [namespaceScope hasNamespaces]
]

{ #category : #testing }
XPathContext >> hasVariables [
	^ self variables notEmpty
]

{ #category : #testing }
XPathContext >> includesFunction: aFunction [
	^ self functions includes: aFunction
]

{ #category : #testing }
XPathContext >> includesVariable: aVariableName [
	^ self variables includesKey: aVariableName
]

{ #category : #initialization }
XPathContext >> initialize [
	locals := OrderedCollection new.
	done := false.
	stack := OrderedCollection new.
	pc := 1. "Start at the beginning"
	^self
]

{ #category : #testing }
XPathContext >> isDeclaredPrefix: aPrefix [
	^ self namespaceScope includesPrefix: aPrefix
]

{ #category : #testing }
XPathContext >> isDeclaredPrefix: aPrefix uri: aURI [
	^ self namespaceScope
		includesPrefix: aPrefix
		mappedTo: aURI
]

{ #category : #functions }
XPathContext >> last [
	self
		push: (self pop
				collect: [:element | element elements last])
]

{ #category : #private }
XPathContext >> mark [
	stack push: pc.
	marker := stack size.
	
]

{ #category : #instructions }
XPathContext >> name: nameIndex [
	| name matches |
	"Processor activeProcess debugWithTitle: 'A problem with names'."
	name := path literalAt: nameIndex.
	matches := (self pop select:
		[:element | (element name = name) or: [name = '*']]).
		"[:element | (element tag type = name) or: [name = '*']])."
	self push: matches.
]

{ #category : #private }
XPathContext >> namespaceScope [
	^ namespaceScope ifNil: [namespaceScope := XMLNamespaceScope new]
]

{ #category : #private }
XPathContext >> namespaceTestForPrefix: aPrefix [
	self hasNamespaces
		ifTrue: [
			^ XPathNamespaceTestForNamespaceURI namespaceURI:
				(self resolvePrefixReference: aPrefix)]
		ifFalse: [
			^ XPathNamespaceTestForPrefix prefix: aPrefix]
]

{ #category : #private }
XPathContext >> namespaceTestForPrefix: aPrefix localName: aLocalName [
	self hasNamespaces
		ifTrue: [
			^ XPathNamespaceTestForNamespaceURIAndLocalName
				namespaceURI: (self resolvePrefixReference: aPrefix)
				localName: aLocalName]
		ifFalse: [
			^ XPathNamespaceTestForName name:
				(aLocalName qualifyWithXMLPrefix: aPrefix)]
]

{ #category : #instructions }
XPathContext >> orAttributes: namesCollection [
	"Look up an attribute"
	| allAttributes |
	
	allAttributes := OrderedCollection new.
	self pop do:
		[:element | 
			| attributes |
			attributes := element attributes asSet.
			( attributes includesAnyOf: namesCollection asSet )
				ifTrue: [ allAttributes add: element attributes ] ].
	self push: allAttributes values
]

{ #category : #instructions }
XPathContext >> parent [
	self push: (self pop collect:
		[:element | element parent]).
]

{ #category : #accessing }
XPathContext >> path [
	^path
]

{ #category : #accessing }
XPathContext >> path: aPath [
	path := aPath
]

{ #category : #instructions }
XPathContext >> pop [
	^ stack removeLast.
]

{ #category : #functions }
XPathContext >> position [
	| positions |
	positions := OrderedCollection new.
	self pop do:
		[:element | positions add: (element parent indexOf: element)].
	self push: positions.
]

{ #category : #instructions }
XPathContext >> push: anObject [
	stack addLast: anObject.
]

{ #category : #instructions }
XPathContext >> query [
	| instruction |
	"Must start with an initial collection of nodes; size = 1"
	"Also, need to skip the document node and start with the root node"
	"self push: (OrderedCollection withAll: root elements)."
	self push: (OrderedCollection with: root).
	self results ifNil: 
		[
			[done] whileFalse:
				[
					| nextPC |
					nextPC := pc + 1.
					instruction := path instructionAt: pc.
					pc := nextPC.
					instruction sentTo: self.
				].
		].
	^self results
]

{ #category : #removing }
XPathContext >> removeFunction: aFunction [
	"use copy-on-write so the default function set isn't modified"
	^ self copiedFunctions remove: aFunction
]

{ #category : #removing }
XPathContext >> removeFunction: aFunction ifAbsent: aBlock [
	"use copy-on-write so the default function set isn't modified"
	^ self copiedFunctions
		remove: aFunction
		ifAbsent: aBlock
]

{ #category : #removing }
XPathContext >> removeFunctions [
	self copiedFunctions removeAll
]

{ #category : #removing }
XPathContext >> removeVariable: aVariable [
	^ self variables removeKey: aVariable
]

{ #category : #removing }
XPathContext >> removeVariable: aVariable ifAbsent: aBlock [
	^ self variables
		removeKey: aVariable
		ifAbsent: aBlock
]

{ #category : #removing }
XPathContext >> removeVariables [
	self variables removeAll
]

{ #category : #private }
XPathContext >> resolveFunctionReference: aFunctionName contextNode: aContextNode arguments: anArgumentArray [
	^ (self
		functionNamed: aFunctionName
		ifAbsent: [self errorUndeclaredFunction: aFunctionName])
			context: self
			contextNode: aContextNode
			arguments: anArgumentArray
]

{ #category : #namespacing }
XPathContext >> resolvePrefix: aPrefix [
	^ self namespaceScope resolvePrefix: aPrefix
]

{ #category : #namespacing }
XPathContext >> resolvePrefix: aPrefix ifUnresolvable: aBlock [
	^ self namespaceScope
		resolvePrefix: aPrefix
		ifUnresolvable: aBlock
]

{ #category : #private }
XPathContext >> resolvePrefixReference: aPrefix [
	^ self
		resolvePrefix: aPrefix
		ifUnresolvable: [self errorUndeclaredPrefix: aPrefix]
]

{ #category : #namespacing }
XPathContext >> resolvePrefixesOfNamespaceURI: aURI [
	^ self namespaceScope resolvePrefixesOfNamespaceURI: aURI
]

{ #category : #private }
XPathContext >> resolveVariableReference: aVariableName [
	^ self
		variableAt: aVariableName
		ifAbsent: [self errorUndeclaredVariable: aVariableName]
]

{ #category : #accessing }
XPathContext >> results [
	^results
]

{ #category : #private }
XPathContext >> revert [
	[stack size > marker]
		whileTrue: [stack pop].
	pc := stack pop.
]

{ #category : #accessing }
XPathContext >> root [
	^root
]

{ #category : #accessing }
XPathContext >> root: rootNode [
	root := rootNode
]

{ #category : #functions }
XPathContext >> text [
	"Return element content"
	| allText |
	allText := OrderedCollection new.
	self pop collect: [:element | allText addAll: element contents].
	self push: allText.
]

{ #category : #namespacing }
XPathContext >> undeclarePrefix: aPrefix [
	self namespaceScope
		unmapPrefix: aPrefix
		ifAbsent: [nil]
]

{ #category : #namespacing }
XPathContext >> undeclarePrefixes [
	self namespaceScope unmapPrefixes
]

{ #category : #accessing }
XPathContext >> variableAt: aVariableName [
	^ self variables
		at: aVariableName
		ifAbsent: [nil]
]

{ #category : #accessing }
XPathContext >> variableAt: aVariableName ifAbsent: aBlock [
	^ self variables
		at: aVariableName
		ifAbsent: aBlock
]

{ #category : #accessing }
XPathContext >> variableAt: aVariableName ifAbsentPut: aBlock [
	^ self variables
		at: aVariableName
		ifAbsentPut: aBlock
]

{ #category : #accessing }
XPathContext >> variableAt: aVariableName put: aValue [
	^ self variables
		at: aVariableName
		put: aValue
]

{ #category : #private }
XPathContext >> variables [
	^ variables ifNil: [variables := Dictionary new]
]

{ #category : #accessing }
XPathContext >> variables: anAssociationCollection [
	variables := Dictionary new: anAssociationCollection size.
	anAssociationCollection associationsDo: [:each |
		variables
			at: each key
			put: each value].
]
