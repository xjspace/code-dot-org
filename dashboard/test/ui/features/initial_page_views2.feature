@eyes
@eyes_ie
Feature: Looking at a few things with Applitools Eyes - Part 2

  Background:
    Given I am on "http://studio.code.org/reset_session"

  Scenario Outline: Logged in simple page view without instructions dialog
    Given I am on "http://studio.code.org/"
    And I am a student
    When I open my eyes to test "<test_name>"
    And I am on "<url>"
    When I rotate to landscape
    And I close the instructions overlay if it exists
    # hack to deflake "free response" scenario below
    And element ".uitest-attachment" is not visible
    Then I see no difference for "initial load" using stitch mode "<stitch_mode>"
    And I close my eyes
    And I sign out
    Examples:
      | url                                                      | test_name                 | stitch_mode |
      | http://studio.code.org/projects/applab/new               | new applab project        | scroll      |
      | http://studio.code.org/                                  | logged in studio homepage | css         |
      | http://studio.code.org/s/allthethings                    | logged in script progress | css         |
      | http://studio.code.org/s/course4/stage/1/puzzle/1        | unplugged video level     | css         |
      | http://studio.code.org/s/allthethings/stage/18/puzzle/14 | embed video               | css         |
      | http://studio.code.org/s/allthethings/stage/27/puzzle/1  | free response             | css         |
