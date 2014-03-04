Feature: @enumeration
  Scenario Outline: Define an @enumeration with explicit @description
    Given I define an enumeration named <name> with description <description>
    When I get the result hash
    Then there should be an enumeration named <name>
    And the enumeration named <name> should have description <description>

    Examples:
    | name | description |
    | AnEnumeration | This is a test enum |
    | AnotherEnumeration | Here is another one! |


  Scenario Outline: Define an @enumeration with implicit description
    Given I define an enumeration named <name> with implicit description <description>
    When I get the result hash
    Then there should be an enumeration named <name>
    And the enumeration named <name> should have description <description>

    Examples:
    | name | description |
    | AnEnumeration | This is a test enum |
    | AnotherEnumeration | Here is another one! |

  Scenario Outline: Define an @enumeration with no description
    Given I define an enumeration
    But I don't give it a description
    When I get the result hash
    Then there should be a parse error

  Scenario Outline: Define an @enumeration with no name
    Given I define an enumeration
    But I don't give it a name
    When I get the result hash
    Then there should be a parse error