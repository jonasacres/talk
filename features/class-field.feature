Feature: @class -> @field
  Scenario Outline: Define a field
    Given I have defined a valid class
    And I give it a field named <name> of type <type> and description <description>
    When I get the result hash
    Then the field <name> should have type <type> and description <description>

    Examples:
    | name | type | description |
    | foobar8 | int8 | I am an 8-bit integer |
    | foobarU16 | uint16 | I am a 16-bit unsigned integer |

  Scenario Outline: Define a field with implicit description
    Given I have defined a valid class
    And I give it a field named <name> of type <type> and implicit description <description>
    When I get the result hash
    Then the field <name> should have type <type> and description <description>

    Examples:
    | name | type | description |
    | foobar8 | int8 | I am an 8-bit integer |
    | foobarU16 | uint16 | I am a 16-bit unsigned integer |

  Scenario Outline: Define a field with a valid primitive type
    Given I have defined a valid class
    And I give it a valid field named foobar of type <type>
    When I get the result hash
    Then the field foobar should have type <type>

    Examples:
    | type |
    | uint8 |
    | uint16 |
    | uint32 |
    | uint64 |
    | int8 |
    | int16 |
    | int32 |
    | int64 |
    | string |
    | object |
    | talkobject |
    | real |
    | bool |

  Scenario Outline: Define a field with an invalid type
    Given I have defined a valid class
    And I give it a valid field named foobar of type <type>
    When I get the result hash
    Then there should be a parse error

    Examples:
    | type |
    | Lies |
    | IAmTheDevil|
    | LookMaNoParse |

  Scenario Outline: Define a field with a sibling class
    Given I have defined a valid class named <sibling>
    And I have defined a valid class
    And I give it a valid field named foobar of type <sibling>
    When I get the result hash
    Then the field foobar should have type <sibling>

    Examples:
    | sibling |
    | Brother |
    | Sister |
    | GenderNeutralSibling |

  Scenario Outline: Define a field with a sibling class referenced by abbreviation
    Given I have defined a valid class named <sibling>
    And I have defined a valid class
    And I give it a valid field named foobar of type <abbrev>
    When I get the result hash
    Then the field foobar should have type <sibling>

    Examples:
    | sibling | abbrev |
    | com.example.Sibling | Sibling |
    | com.example.Sibling | example.Sibling |
    | com.example.sibling | com.example.Sibling |

  Scenario: Define a field that refers to its container class
    Given I have defined a valid class named Container
    And I give it a valid field named foobar of type Container
    When I get the result hash
    Then the field foobar should have type Container

  Scenario Outline: Define a field with an @see class
    Given I have defined a valid class named <other>
    And I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @see class <other>
    When I get the result hash
    Then the field foobar should have an @see class <other>

    Examples:
    | other |
    | AClass |
    | CoolClass |
    | LameClass |

  Scenario: Define a field with an @see class that doesn't exist
    Given I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @see class DoesntExist
    When I get the result hash
    Then there should be a parse error

  Scenario Outline: Define a field with an @see glossary
    Given I have defined a valid glossary named <other>
    And I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @see glossary <other>
    When I get the result hash
    Then the field foobar should have an @see glossary <other>

    Examples:
    | other |
    | BestBabyNamesFor2014 |
    | LexiconOfCthulhu |
    | AdorableAnimals |

  Scenario: Define a field with an @see glossary that doesn't exist
    Given I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @see glossary DoesntExist
    When I get the result hash
    Then there should be a parse error

  Scenario Outline: Define a field with an @see enumeration
    Given I have defined a valid enumeration named <other>
    And I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @see enumeration <other>
    When I get the result hash
    Then the field foobar should have an @see enumeration <other>

    Examples:
    | other |
    | BestBabyNamesFor2014 |
    | LexiconOfCthulhu |
    | AdorableAnimals |

  Scenario Outline: Define a field with an @see enum
    Given I have defined a valid enumeration named <other>
    And I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @see enum <other>
    When I get the result hash
    Then the field foobar should have an @see enumeration <other>

    Examples:
    | other |
    | HowILoveThee |
    | MarksEvilBitmasks |
    | WaysToLeaveYourLover |

  Scenario: Define a field with an @see enumeration that doesn't exist
    Given I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @see enumeration DoesntExist
    When I get the result hash
    Then there should be a parse error  

  Scenario Outline: Define a field with @caveats
    Given I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @caveat <message_1>
    And I give foobar @caveat <message_2>
    When I get the result hash
    Then the field foobar should have a @caveat <message_1>
    And the field foobar should have a @caveat <message_2>

    Examples:
    | message_1 | message_2 |
    | This field is pure evil | May contain null, as well as fatal amounts of arsenic |
    | Field might be garbage | Field might also have the information you need to survive |

  Scenario Outline: Define a field as @deprecated
    Given I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @deprecated <message>
    When I get the result hash
    Then the field foobar should have @deprecated <message>

    Examples:
    | message |
    | It wasn't working out |
    | It's not the field, it's us |
    | We still want to be friends with this field and hope it moves on to other classes that will love it for who it is |

  Scenario: Define a field as @deprecated twice
    Given I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @deprecated once
    And I give foobar @deprecated again
    When I get the result hash
    Then there should be a parse error

  Scenario Outline: Define a field with an @version
    Given I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @version <version>
    When I get the result hash
    Then the field foobar should have @version <version>

    Examples:
    | version |
    | 1 |
    | 3.0 |
    | sheepishly stroked lion |

  Scenario Outline: Define a field with two @version tags
    Given I have defined a valid class
    And I give it a valid field named foobar
    And I give foobar @version <version_1>
    And I give foobar @version <version_2>
    When I get the result hash
    Then there should be a parse error

    Examples:
    | version_1 | version_2 |
    | 1.0 | 1.0 |
    | 1.0 | 2.0 |
