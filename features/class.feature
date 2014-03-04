Feature: @class
  Scenario Outline: Define a class with an explicit @description
    Given I have defined a class named <name>
    And I have given <description> as a @description
    When I get the result hash 
    Then there should be a class named <name>
    And it should have description <description>

    Examples:
    | name | description |
    | Lumberjack | I am a lumberjack, and I am acceptable |
    | com.example.JavaClass | I have a hierarchical name |

  Scenario Outline: Define a class with an implicit @description
    Given I have defined a class named <name>
    And I have given <description> as an implied description
    When I get the result hash 
    Then there should be a class named <name>
    And it should have description <description>

    Examples:
    | name | description |
    | Lumberjack | I am a lumberjack, and I am acceptable |
    | com.example.JavaClass | I have a hierarchical name |

  Scenario Outline: Define a class without a description
    Given I have defined a class named NoDescriptionClsas
    But I don't give a description
    When I get the result hash
    Then there should be a parse error

  Scenario Outline: Define a class with a duplicate name
    Given I have defined a class named DuplicateClass
    And I have given it some random bullshit as a @description
    And I define another class also named DuplicateClass
    When I get the result hash 
    Then there should be a parse error

  Scenario Outline: Define a class with @inherits
    Given I have defined a valid class named <base>
    And I have defined a valid class named ChildClass
    And I give it @inherits <base>
    When I get the result hash
    Then the class ChildClass should have @inherits <base>

    Examples:
    | base |
    | BaseClass |
    | YourDaddy |

  Scenario Outline: Define a class that @inherits from an undefined class
    Given I have defined a valid class named ChildClass
    And I give it @inherits <base>
    When I get the result hash
    Then there should be a parse error

    Examples:
    | DoesntExist |
    | uint16 |
    | string |
    | talkobject |

  Scenario Outline: Define a class that @inherits twice
    Given I have defined a valid class named BaseClass1
    And I have defined a valid class named BaseClass2
    And I have defined a valid class named ChildClass
    And I give it @inherits <base_1>
    And I give it @inherits <base_2>
    When I get the result hash
    Then there should be a parse error

    Examples:
    | base_1 | base_2 |
    | BaseClass1 | BaseClass1 |
    | BaseClass1 | BaseClass2 |

  Scenario Outline: Define a class that sets @implement
    Given I have defined a valid class named NoImplementClass
    And I give it @implement <implement>
    When I get the result hash
    Then the class ChildClass should have @implements <value>

    Examples:
    | implement | value |
    | 0 | 0 |
    | off | 0 |
    | false | 0 |
    | no | 0 |
    | NO | 0 |
    | False | 0 |
    | 1 | 1 |
    | on | 1 |
    | true | 1 |
    | yes | 1 |