require 'cdo/url_converter'

DEFAULT_WAIT_TIMEOUT = 2.minutes
SHORT_WAIT_TIMEOUT = 30.seconds
MODULE_PROGRESS_COLOR_MAP = {not_started: 'rgb(255, 255, 255)', in_progress: 'rgb(239, 205, 28)', completed: 'rgb(14, 190, 14)'}

def wait_until(timeout = DEFAULT_WAIT_TIMEOUT)
  Selenium::WebDriver::Wait.new(timeout: timeout).until do
    yield
  rescue Selenium::WebDriver::Error::UnknownError => e
    puts "Unknown error: #{e}"
    false
  rescue Selenium::WebDriver::Error::WebDriverError => e
    raise unless e.message.include?('no such element')
    false
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    false
  end
end

def wait_short_until(&block)
  wait_until(SHORT_WAIT_TIMEOUT, &block)
end

def element_stale?(element)
  element.enabled?
  false
rescue Selenium::WebDriver::Error::JavascriptError => e
  e.message.starts_with? 'Element does not exist in cache'
rescue Selenium::WebDriver::Error::UnknownError => e
  puts "Unknown error: #{e}"
  true
rescue Selenium::WebDriver::Error::StaleElementReferenceError
  true
rescue Selenium::WebDriver::Error::WebDriverError => e
  return true if e.message.include?('stale element reference') ||
    e.message.include?('no such element')
  puts "Unknown error: #{e}"
  true
end

def page_load(wait = true, blank_tab: false)
  if wait
    root = @browser.find_element(css: ':root')
    tabs = @browser.window_handles if wait == 'tab'
    yield
    if tabs
      new_tab = wait_until {(@browser.window_handles - tabs).first}
      @browser.switch_to.window(new_tab)
    end
    wait_until {element_stale?(root)}
    unless blank_tab
      wait_until do
        (url = @browser.current_url) != '' &&
           url != 'about:blank' &&
          @browser.execute_script('return document.readyState;') == 'complete'
      end
    end
  else
    yield
  end
end

def replace_hostname(url)
  UrlConverter.new(
    dashboard_host: ENV['DASHBOARD_TEST_DOMAIN'],
    pegasus_host: ENV['PEGASUS_TEST_DOMAIN'],
    hourofcode_host: ENV['HOUROFCODE_TEST_DOMAIN'],
    csedweek_host: ENV['CSEDWEEK_TEST_DOMAIN'],
    advocacy_host: ENV['ADVOCACY_TEST_DOMAIN']
  ).replace_origin(url)
end

# When an individual step fails in a call to steps, one gets no feedback about
# which step failed. This splits a set of steps into individual steps, and calls
# each separately, so that when one fails we're told which.
def individual_steps(steps)
  steps.split("\n").map(&:strip).each do |separate_step|
    steps separate_step
  end
end

def navigate_to(url)
  Retryable.retryable(on: RSpec::Expectations::ExpectationNotMetError, sleep: 10, tries: 3) do
    with_read_timeout(DEFAULT_WAIT_TIMEOUT + 5.seconds) do
      @browser.navigate.to url
      wait_until do
        @browser.execute_script('return document.readyState;') == 'complete'
      end
    end
    refute_bad_gateway_or_site_unreachable
  end
  install_js_error_recorder
end

Given /^I am on "([^"]*)"$/ do |url|
  check_window_for_js_errors('before navigation')
  navigate_to replace_hostname(url)
end

When /^I wait to see (?:an? )?"([.#])([^"]*)"$/ do |selector_symbol, name|
  selection_criteria = selector_symbol == '#' ? {id: name} : {class: name}
  wait_until {!@browser.find_elements(selection_criteria).empty?}
end

When /^I go to a new tab$/ do
  page_load('tab', blank_tab: true) do
    @browser.execute_script('window.open();')
  end
end

When /^I close the current tab$/ do
  @browser.close
  tabs = @browser.window_handles
  @browser.switch_to.window(tabs.first) if tabs.any?
end

When /^I switch tabs$/ do
  tab = @browser.window_handle
  @browser.switch_to.window(@browser.window_handles.detect {|handle| handle != tab})
end

When /^I switch to the first iframe$/ do
  $default_window = @browser.window_handle
  @browser.switch_to.frame @browser.find_element(tag_name: 'iframe')
end

# Can switch out of iframe content
When /^I switch to the default content$/ do
  @browser.switch_to.default_content
end

When /^I close the instructions overlay if it exists$/ do
  steps 'When I click selector "#overlay" if it exists'
end

When /^I wait for the page to fully load$/ do
  steps <<-STEPS
    When I wait to see "#runButton"
    And I wait to see ".header_user"
    And I close the instructions overlay if it exists
  STEPS
end

When /^I close the dialog$/ do
  # Add a wait to closing dialog because it's sometimes animated, now.
  steps <<-STEPS
    When I press "x-close"
    And I wait for 0.75 seconds
  STEPS
end

When /^I wait until "([^"]*)" in localStorage equals "([^"]*)"$/ do |key, value|
  wait_until {@browser.execute_script("return localStorage.getItem('#{key}') === '#{value}';")}
end

When /^I reset the puzzle to the starting version$/ do
  steps <<-STEPS
    Then I click selector "#versions-header"
    And I wait to see a dialog titled "Version History"
    And I see "#showVersionsModal"
    And I wait until element "button:contains(Start over)" is visible
    And I close the dialog
    And I wait until element "#showVersionsModal" is gone
    And I wait for 3 seconds
    Then I click selector "#versions-header"
    And I wait until element "button:contains(Start over)" is visible
    And I click selector "button:contains(Start over)"
    And I click selector "#confirm-button"
    And I wait until element "#showVersionsModal" is gone
    And I wait for 3 seconds
  STEPS
end

When /^I reset the puzzle$/ do
  @browser.find_element(:css, '#clear-puzzle-header').click
  @browser.find_element(:css, '#confirm-button').click
end

Then /^I see "([.#])([^"]*)"$/ do |selector_symbol, name|
  selection_criteria = selector_symbol == '#' ? {id: name} : {class: name}
  selection_criteria = {css: "#{selector_symbol}#{name}"} if name.include?('#')
  @browser.find_element(selection_criteria)
end

When /^I wait until (?:element )?"([^"]*)" (?:has|contains) text "([^"]*)"$/ do |selector, text|
  wait_until {@browser.execute_script("return $(#{selector.dump}).text();").include? text}
end

When /^I wait until (?:element )?"([^"]*)" does not (?:have|contain) text "([^"]*)"$/ do |selector, text|
  wait_short_until do
    element_text = @browser.execute_script("return $(#{selector.dump}).text();")
    !element_text.include? text
  end
end

When /^I wait until the first (?:element )?"([^"]*)" (?:has|contains) text "([^"]*)"$/ do |selector, text|
  wait_until {@browser.execute_script("return $(#{selector.dump}).first().text();").include? text}
end

def jquery_is_element_visible(selector)
  "return $(#{selector.dump}).is(':visible') && $(#{selector.dump}).css('visibility') !== 'hidden';"
end

When /^I wait until element "([^"]*)" is (not )?visible$/ do |selector, negation|
  wait_for_jquery
  wait_until {@browser.execute_script(jquery_is_element_visible(selector)) == negation.nil?}
end

When /^I wait until (?:element )?"([.#])([^"]*)" is (not )?enabled$/ do |selector_symbol, name, negation|
  selection_criteria = selector_symbol == '#' ? {id: name} : {class: name}
  wait_until do
    element = @browser.find_element(selection_criteria)
    element.enabled? == negation.nil?
  end
end

Then /^I wait up to ([\d\.]+) seconds for element "([^"]*)" to be visible$/ do |seconds, selector|
  wait_for_jquery
  Selenium::WebDriver::Wait.new(timeout: seconds.to_f).until do
    @browser.execute_script(jquery_is_element_visible(selector))
  end
end

When /^I wait until element "([^"]*)" is in the DOM$/ do |selector|
  wait_for_jquery
  wait_until {@browser.execute_script("return $(#{selector.dump}).length > 0")}
end

Then /^I wait until element "([.#])([^"]*)" is gone$/ do |selector_symbol, name|
  selection_criteria = selector_symbol == '#' ? {id: name} : {class: name}
  wait_until {@browser.find_elements(selection_criteria).empty?}
end

# Required for inspecting elements within an iframe
When /^I wait until element "([^"]*)" is visible within element "([^"]*)"$/ do |selector, parent_selector|
  wait_until {@browser.execute_script("return $(#{selector.dump}, $(#{parent_selector.dump}).contents()).is(':visible')")}
end

When /^I wait until jQuery Ajax requests are finished$/ do
  wait_short_until {@browser.execute_script("return $.active == 0")}
end

Then /^I make all links open in the current tab$/ do
  @browser.execute_script("$('a[target=_blank]').attr('target', '_parent');")
end

Then /^check that I am on "([^"]*)"$/ do |url|
  url = replace_hostname(url)
  expect(@browser.current_url).to eq(url)
end

Then /^I wait until current URL contains "([^"]*)"$/ do |url|
  url = replace_hostname(url)
  wait_until {@browser.current_url.include? url}
end

And /^check that the URL matches "([^"]*)"$/ do |regex_text|
  expect(@browser.current_url.match(regex_text).nil?).to eq(false)
end

Then /^I wait until I am on "([^"]*)"$/ do |url|
  url = replace_hostname(url)
  wait_until {@browser.current_url == url}
end

Then /^check that the URL contains "([^"]*)"$/i do |url|
  url = replace_hostname(url)
  expect(@browser.current_url).to include(url)
end

When /^I wait for (\d+(?:\.\d*)?) seconds?$/ do |seconds|
  sleep seconds.to_f
end

When /^I rotate to landscape$/ do
  if ENV['BS_ROTATABLE'] == "true"
    @browser.rotate(:landscape)
  end
end

When /^I rotate to portrait$/ do
  if ENV['BS_ROTATABLE'] == "true"
    @browser.rotate(:portrait)
  end
end

When /^I press "([^"]*)"(?: to load a new (page|tab))?$/ do |button, load|
  wait_short_until do
    @button = @browser.find_element(id: button)
  end
  page_load(load) {@button.click}
end

When /^I press the child number (.*) of class "([^"]*)"( to load a new page)?$/ do |number, selector, load|
  wait_short_until do
    @elements = @browser.find_elements(:css, selector)
    @element = @elements[number.to_i]
  end

  page_load(load) do
    @element.click
  rescue
    # Single retry to compensate for element changing between find and click
    @element = @browser.find_element(:css, selector)
    @element.click
  end
end

When /^I press the first "([^"]*)" element(?: to load a new (page|tab))?$/ do |selector, load|
  wait_short_until do
    @element = @browser.find_element(:css, selector)
  end
  page_load(load) do
    @element.click
  rescue
    # Single retry to compensate for element changing between find and click
    @element = @browser.find_element(:css, selector)
    @element.click
  end
end

When /^I press the "([^"]*)" button( to load a new page)?$/ do |button_text, load|
  wait_short_until do
    @button = @browser.find_element(:css, "input[value='#{button_text}']")
  end
  page_load(load) {@button.click}
end

When /^I press "([^"]*)" using jQuery( to load a new page)?$/ do |selector, load|
  page_load(load) do
    @browser.execute_script("$(#{selector.dump}).click()")
  end
end

When /^I press SVG selector "([^"]*)"$/ do |selector|
  @browser.execute_script("$(#{selector.dump}).simulate('drag', function(){});")
end

When /^I press the last button with text "([^"]*)"( to load a new page)?$/ do |name, load|
  name_selector = "button:contains(#{name})"
  page_load(load) do
    @browser.execute_script("$('" + name_selector + "').simulate('drag', function(){});")
  end
end

When /^I (?:open|close) the small footer menu$/ do
  menu_selector = 'div.small-footer-base a.more-link'
  steps %{
    Then I wait until element "#{menu_selector}" is visible
    And I click selector "#{menu_selector}"
  }
end

When /^I press menu item "([^"]*)"$/ do |menu_item_text|
  menu_item_selector = "ul#more-menu a:contains(#{menu_item_text})"
  steps %{
    Then I wait until element "#{menu_item_selector}" is visible
    And I click selector "#{menu_item_selector}"
  }
end

When /^I press the settings cog$/ do
  cog_selector = '.settings-cog:visible'
  steps %{
    Then I wait until element "#{cog_selector}" is visible
    And I click selector "#{cog_selector}"
  }
end

When /^I press the settings cog menu item "([^"]*)"$/ do |item_text|
  menu_item_selector = ".settings-cog-menu:visible .pop-up-menu-item:contains(#{item_text})"
  steps %{
    Then I wait until element "#{menu_item_selector}" is visible
    And I click selector "#{menu_item_selector}"
  }
end

When /^I select the "([^"]*)" small footer item( to load a new page)?$/ do |menu_item_text, load|
  page_load(load) do
    steps %{
      Then I open the small footer menu
      And I press menu item "#{menu_item_text}"
    }
  end
end

When /^I press the SVG text "([^"]*)"$/ do |name|
  name_selector = "text:contains(#{name})"
  @browser.execute_script("$('" + name_selector + "').simulate('drag', function(){});")
end

And(/^I scroll to "([^"]*)"$/) do |selector|
  @browser.find_element(:css, selector).location_once_scrolled_into_view
end

When /^I select the "([^"]*)" option in dropdown "([^"]*)"( to load a new page)?$/ do |option_text, element_id, load|
  select_dropdown(@browser.find_element(:id, element_id), option_text, load)
end

When /^I select the "([^"]*)" option in dropdown named "([^"]*)"( to load a new page)?$/ do |option_text, element_name, load|
  select_dropdown(@browser.find_element(:css, "select[name=#{element_name}]"), option_text, load)
end

def select_dropdown(element, option_text, load)
  element.location_once_scrolled_into_view
  page_load(load) do
    select = Selenium::WebDriver::Support::Select.new(element)
    select.select_by(:text, option_text)
  end
end

When /^I open the topmost blockly category "([^"]*)"$/ do |name|
  name_selector = ".blocklyTreeLabel:contains(#{name})"
  # seems we usually have two of these item, and want the second if the function
  # editor is open, the first if it isn't
  @browser.execute_script(
    "var val = Blockly.functionEditor && Blockly.functionEditor.isOpen() ? 1 : 0; " \
    "$('#{name_selector}').get(val).dispatchEvent(new MouseEvent('mousedown', {"\
      "bubbles: true,"\
      "cancelable: true,"\
      "view: window"\
    "}))"
  )
rescue
  script = "var val = Blockly.functionEditor && Blockly.functionEditor.isOpen() ? 1 : 0; " \
    "$('" + name_selector + "').eq(val).simulate('drag', function(){});"
  @browser.execute_script(script)
end

And(/^I open the blockly category with ID "([^"]*)"$/) do |id|
  # jQuery needs \\s to allow :s and .s in ID selectors
  # Escaping those gives us \\\\ per-character
  category_selector = "#\\\\:#{id}\\\\.label"
  @browser.execute_script(
    "$('#{category_selector}').last().get(0).dispatchEvent(new MouseEvent('mousedown', {"\
      "bubbles: true,"\
      "cancelable: true,"\
      "view: window"\
    "}))"
  )
rescue
  @browser.execute_script("$('" + category_selector + "').last().simulate('drag', function(){});")
end

When /^I press dropdown button with text "([^"]*)"$/ do |text|
  @browser.execute_script("$('.goog-flat-menu-button-caption:contains(#{text})').simulate('drag', function(){});")
end

When /^I press dropdown item with text "([^"]*)"$/ do |text|
  @browser.execute_script("$('.goog-menuitem:contains(#{text})').last().simulate('drag', function(){});")
end

When /^I press the edit button on a function call named "([^"]*)"$/ do |text|
  @browser.execute_script("$('.blocklyDraggable:contains(#{text})').find('.blocklyIconGroup:contains(edit)').first().simulate('drag', function(){})")
end

When /^I press dropdown item "([^"]*)"$/ do |index|
  @browser.execute_script("$('.goog-menuitem').eq(#{index}).simulate('drag', function(){});")
end

When /^I press a button with xpath "([^"]*)"$/ do |xpath|
  wait_until do
    @button = @browser.find_element(:xpath, xpath)
  end
  @button.click
end

# Prefer clicking with selenium over jquery, since selenium clicks will fail
# if the target element is obscured by another element.
When /^I click "([^"]*)"( once it exists)?(?: to load a new (page|tab))?$/ do |selector, wait, load|
  find = -> {@browser.find_element(:css, selector)}
  element = wait ? wait_until(&find) : find.call
  page_load(load) {element.click}
end

When /^I select the end of "([^"]*)"$/ do |selector|
  @browser.execute_script("document.querySelector(\"#{selector}\").setSelectionRange(9999, 9999);")
end

When /^I click selector "([^"]*)"(?: to load a new (page|tab))?$/ do |jquery_selector, load|
  # normal a href links can only be clicked this way
  page_load(load) do
    @browser.execute_script("$(\"#{jquery_selector}\")[0].click();")
  end
end

When /^I click selector "([^"]*)" if it exists$/ do |jquery_selector|
  if @browser.execute_script("return $(\"#{jquery_selector}\").length > 0")
    @browser.execute_script("$(\"#{jquery_selector}\")[0].click();")
  end
end

When /^I click selector "([^"]*)" once I see it(?: to load a new (page|tab))?$/ do |selector, load|
  wait_until do
    @browser.execute_script("return $(\"#{selector}:visible\").length != 0;")
  end
  page_load(load) do
    @browser.execute_script("$(\"#{selector}\")[0].click();")
  end
end

When /^I click selector "([^"]*)" if I see it$/ do |selector|
  wait_until(5) do
    @browser.execute_script("return $(\"#{selector}:visible\").length != 0;")
  end
  @browser.execute_script("$(\"#{selector}:visible\")[0].click();")
rescue Selenium::WebDriver::Error::TimeOutError
  # Element never appeared, ignore it
end

When /^I focus selector "([^"]*)"$/ do |jquery_selector|
  @browser.execute_script("$(\"#{jquery_selector}\")[0].focus();")
end

When /^I blur selector "([^"]*)"$/ do |jquery_selector|
  @browser.execute_script("$(\"#{jquery_selector}\")[0].blur();")
end

When /^I send click events to selector "([^"]*)"$/ do |jquery_selector|
  # svg elements can only be clicked this way
  @browser.execute_script("$(\"#{jquery_selector}\").click();")
end

When /^I press delete$/ do
  script = "Blockly.mainBlockSpaceEditor.onKeyDown_("
  script += "{"
  script += "  target: {},"
  script += "  preventDefault: function() {},"
  script += "  keyCode: $.simulate.keyCode['DELETE']"
  script += "})"
  @browser.execute_script(script)
end

When /^I hold key "([^"]*)"$/ do |key_code|
  script = "$(window).simulate('keydown',  {keyCode: $.simulate.keyCode['#{key_code}']})"
  @browser.execute_script(script)
end

When /^I type "([^"]*)" into "([^"]*)"$/ do |input_text, selector|
  type_into_selector("\"#{input_text}\"", selector)
end

When /^I type '([^']*)' into "([^"]*)"$/ do |input_text, selector|
  type_into_selector("\'#{input_text}\'", selector)
end

# The selector should be wrapped in appropriate quotes when passed into here.
def type_into_selector(input_text, selector)
  wait_for_jquery
  @browser.execute_script("$('#{selector}').val(#{input_text})")
  @browser.execute_script("$('#{selector}').keyup()")
  @browser.execute_script("$('#{selector}').change()")
end

When /^I set text compression dictionary to "([^"]*)"$/ do |input_text|
  @browser.execute_script("editor.setValue('#{input_text}')")
end

Then /^I should see title "([^"]*)"$/ do |title|
  expect(@browser.title).to eq(title)
end

Then /^evaluate JavaScript expression "([^"]*)"$/ do |expression|
  expect(@browser.execute_script("return #{expression}")).to eq(true)
end

Then /^execute JavaScript expression "([^"]*)"$/ do |expression|
  @browser.execute_script("return #{expression}")
end

Then /^mark the current level as completed on the client/ do
  @browser.execute_script 'dashboard.clientState.trackProgress(true, 1, 100, "hourofcode", appOptions.serverLevelId)'
end

Then /^I navigate to the course page for "([^"]*)"$/ do |course|
  steps %{
    Then I am on "http://studio.code.org/s/#{course}"
    And I wait to see ".user-stats-block"
  }
end

# The second regex matches strings in which all double quotes and backslashes
# are quoted (preceded by a backslash).
Then /^element "([^"]*)" has text "((?:[^"\\]|\\.)*)"$/ do |selector, expected_text|
  element_has_text(selector, expected_text)
end

Then /^element "([^"]*)" has css property "([^"]*)" equal to "([^"]*)"$/ do |selector, property, expected_value|
  element_has_css(selector, property, expected_value)
end

# Example use case: checking webkit and moz overrides for css properties
Then /^element "([^"]*)" has one of css properties "([^"]*)" equal to "([^"]*)"$/ do |selectors, properties, expected_value|
  properties = properties.split(',')
  element_has_css_multiple_properties(selectors, properties, expected_value)
end

Then /^I wait up to ([\d\.]+) seconds for element "([^"]*)" to have css property "([^"]*)" equal to "([^"]*)"$/ do |seconds, selector, property, expected_value|
  Selenium::WebDriver::Wait.new(timeout: seconds.to_f).until do
    element_css_value(selector, property) == expected_value
  end
end

Then /^elements "([^"]*)" have css property "([^"]*)" equal to "([^"]*)"$/ do |selector, property, expected_values|
  elements_have_css(selector, property, expected_values)
end

Then /^I set selector "([^"]*)" text to "([^"]*)"$/ do |selector, text|
  @browser.execute_script("$(\"#{selector}\").text(\"#{text}\");")
end

Then /^element "([^"]*)" has escaped text "((?:[^"\\]|\\.)*)"$/ do |selector, expected_text|
  # Add more unescaping rules here as needed.
  expected_text.gsub!(/\\n/, "\n")
  element_has_text(selector, expected_text)
end

Then /^element "([^"]*)" has html "([^"]*)"$/ do |selector, expected_html|
  element_has_html(selector, expected_html)
end

Then /^I wait to see a dialog titled "((?:[^"\\]|\\.)*)"$/ do |expected_text|
  steps %{
    Then I wait to see a ".dialog-title"
    And element ".dialog-title" has text "#{expected_text}"
  }
end

Then /^I wait to see a dialog containing text "((?:[^"\\]|\\.)*)"$/ do |expected_text|
  steps %{
    Then I wait to see a ".modal-body"
    And element ".modal-body" contains text "#{expected_text}"
  }
end

Then /^I wait to see a congrats dialog with title containing "((?:[^"\\]|\\.)*)"$/ do |expected_text|
  steps %{
    Then I wait to see a ".congrats"
    And element ".congrats" contains text "#{expected_text}"
  }
end

Then /^I reopen the congrats dialog unless I see the sharing input/ do
  next if @browser.execute_script("return $('#sharing-input').length > 0;")
  puts "reopening congrats dialog"
  individual_steps %{
    And I press "again-button"
    And I wait until element ".congrats" is not visible
    And I press "resetButton"
    And I press "runButton"
    And I click selector "#finishButton" if I see it
    And I click selector "#rightButton" if I see it
    Then I wait to see a ".congrats"
    Then element ".congrats" contains text "Congratulations"
  }
end

# pixelation and other dashboard levels pull a bunch of hidden dialog elements
# into the dom, so we have to check for the dialog more carefully.
Then /^I wait to see a visible dialog with title containing "((?:[^"\\]|\\.)*)"$/ do |expected_text|
  steps %{
    And I wait to see ".modal-body"
    And element ".modal-body .dialog-title" is visible
    And element ".modal-body .dialog-title" contains text "#{expected_text}"
  }
end

Then /^element "([^"]*)" has "([^"]*)" text from key "((?:[^"\\]|\\.)*)"$/ do |selector, language, loc_key|
  element_has_i18n_text(selector, language, loc_key)
end

Then /^element "([^"]*)" contains text "((?:[^"\\]|\\.)*)"$/ do |selector, expected_text|
  element_contains_text(selector, expected_text)
end

Then /^element "([^"]*)" does not contain text "((?:[^"\\]|\\.)*)"$/ do |selector, expected_text|
  expect(element_contains_text?(selector, expected_text)).to be false
end

Then /^element "([^"]*)" eventually contains text "((?:[^"\\]|\\.)*)"$/ do |selector, expected_text|
  wait_until {element_contains_text?(selector, expected_text)}
end

Then /^element "([^"]*)" has value "([^"]*)"$/ do |selector, expected_value|
  element_value_is(selector, expected_value)
end

Then /^element "([^"]*)" has escaped value "([^"]*)"$/ do |selector, expected_value|
  element_value_is(selector, YAML.load(%Q(---\n"#{expected_value}"\n)))
end

Then /^element "([^"]*)" has escaped value '([^']*)'$/ do |selector, expected_value|
  element_value_is(selector, YAML.load(%Q(---\n"#{expected_value.gsub('"', '\"')}"\n)))
end

Then /^element "([^"]*)" is (not )?checked$/ do |selector, negation|
  value = @browser.execute_script("return $(\"#{selector}\").is(':checked');")
  expect(value).to eq(negation.nil?)
end

Then /^I use jquery to set the text of "([^"]*)" to "([^"]*)"$/ do |selector, value|
  @browser.execute_script("$(\"#{selector}\").text(\"#{value}\");")
end

Then /^element "([^"]*)" has attribute "((?:[^"\\]|\\.)*)" equal to "((?:[^"\\]|\\.)*)"$/ do |selector, attribute, expected_text|
  element_has_attribute(selector, attribute, replace_hostname(expected_text))
end

Then /^element "([^"]*)" is (not )?read-?only$/ do |selector, negation|
  readonly = @browser.execute_script("return $(\"#{selector}\").attr(\"readonly\");")
  if negation.nil?
    expect(readonly).to eq('readonly')
  else
    expect(readonly.nil?).to eq(true)
  end
end

# The second regex encodes that ids should not contain spaces or quotes.
# While this is stricter than HTML5, it is looser than HTML4.
Then /^element "([^"]*)" has id "([^ "']+)"$/ do |selector, id|
  element_has_id(selector, id)
end

def jquery_element_exists(selector)
  "return $(#{selector.dump}).length > 0"
end

def element_exists?(selector)
  @browser.execute_script(jquery_element_exists(selector))
end

def element_visible?(selector)
  @browser.execute_script(jquery_is_element_visible(selector))
end

Then /^element "([^"]*)" is (not )?visible$/ do |selector, negation|
  expect(element_visible?(selector)).to eq(negation.nil?)
end

Then /^element "([^"]*)" does not exist/ do |selector|
  expect(element_exists?(selector)).to eq(false)
end

Then /^element "([^"]*)" is hidden$/ do |selector|
  expect(element_visible?(selector)).to eq(false)
end

And (/^I select age (\d+) in the age dialog/) do |age|
  steps %Q{
    And element ".age-dialog" is visible
    And I select the "#{age}" option in dropdown "uitest-age-selector"
    And I click selector "#uitest-submit-age"
  }
end

And (/^I do not see "([^"]*)" option in the dropdown "([^"]*)"/) do |option, selector|
  select_options_text = @browser.execute_script("return $('#{selector} option').val()")
  expect((select_options_text.include? option)).to eq(false)
end

And (/^I see option "([^"]*)" or "([^"]*)" in the dropdown "([^"]*)"/) do |option_alpha, option_beta, selector|
  select_options_text = @browser.execute_script("return $('#{selector} option').text()")
  expect((select_options_text.include? option_alpha) || (select_options_text.include? option_beta)).to eq(true)
end

And (/^I wait for the song selector to load/) do
  wait_for_jquery
  wait_until {@browser.execute_script("return !!$('#song_selector').val();")}
end

def has_class?(selector, class_name)
  @browser.execute_script("return $(#{selector.dump}).hasClass('#{class_name}')")
end

Then /^element "([^"]*)" has class "([^"]*)"$/ do |selector, class_name|
  expect(has_class?(selector, class_name)).to eq(true)
end

Then /^element "([^"]*)" (?:does not|doesn't) have class "([^"]*)"$/ do |selector, class_name|
  expect(has_class?(selector, class_name)).to eq(false)
end

Then /^SVG element "([^"]*)" within element "([^"]*)" has class "([^"]*)"$/ do |selector, parent_selector, class_name|
  # Can't use jQuery hasClass here, due to limited SVG support
  class_list = @browser.execute_script("return $(\"#{selector}\", $(\"#{parent_selector}\").contents())[0].getAttribute(\"class\")")
  expect(class_list).to include(class_name)
end

def disabled?(selector)
  @browser.execute_script("return $('#{selector}')[0].getAttribute('disabled') !== null || $('#{selector}').hasClass('disabled')")
end

Then /^element "([^"]*)" is (?:enabled|not disabled)$/ do |selector|
  expect(disabled?(selector)).to eq(false)
end

Then /^I wait until "([^"]*)" is (not )?disabled$/ do |selector, negation|
  wait_short_until do
    disabled?(selector) == negation.nil?
  end
end

Then /^element "([^"]*)" is disabled$/ do |selector|
  expect(disabled?(selector)).to eq(true)
end

And /^output url$/ do
  puts @browser.current_url
end

Then /^I drag "([^"]*)" to "([^"]*)"$/ do |source_selector, destination_selector|
  @browser.execute_script(generate_generic_drag_code(source_selector, destination_selector, 0, 0))
end

Then /^there's an image "([^"]*)"$/ do |path|
  exists = @browser.execute_script("return $('img[src*=\"#{path}\"]').length != 0;")
  expect(exists).to eq(true)
end

Then /^I print the HTML contents of element "([^"]*)"$/ do |element_to_print|
  puts @browser.execute_script("return $('##{element_to_print}').html()")
end

Then /^I wait to see an image "([^"]*)"$/ do |path|
  wait_until {@browser.execute_script("return $('img[src*=\"#{path}\"]').length != 0;")}
end

Then /^I click an image "([^"]*)"$/ do |path|
  @browser.execute_script("$('img[src*=\"#{path}\"]').click();")
end

Then /^I see jquery selector (.*)$/ do |selector|
  exists = @browser.execute_script("return $(\"#{selector}\").length != 0;")
  expect(exists).to eq(true)
end

Then /^I see (\d*) of jquery selector (.*)$/ do |num, selector|
  expect(@browser.execute_script("return $(\"#{selector}\").length;")).to eq(num.to_i)
end

Then /^I wait until I (don't )?see selector "(.*)"$/ do |negation, selector|
  wait_until do
    @browser.execute_script("return $(\"#{selector}:visible\").length != 0;") == negation.nil?
  end
end

Then /^there's a div with a background image "([^"]*)"$/ do |path|
  exists = @browser.execute_script("return $('div').filter(function(){return $(this).css('background-image').indexOf('#{path}') != -1 }).length > 0")
  expect(exists).to eq(true)
end

Then /^there's an SVG image "([^"]*)"$/ do |path|
  exists = @browser.execute_script("return $('image').filter('[xlink\\\\:href*=\"#{path}\"]').length != 0")
  expect(exists).to eq(true)
end

Then /^there's not an SVG image "([^"]*)"$/ do |path|
  exists = @browser.execute_script("return $('image').filter('[xlink\\\\:href*=\"#{path}\"]').length != 0")
  expect(exists).to eq(false)
end

Then(/^"([^"]*)" should be in front of "([^"]*)"$/) do |selector_front, selector_behind|
  front_z_index = @browser.execute_script("return $('#{selector_front}').css('z-index')").to_i
  behind_z_index = @browser.execute_script("return $('#{selector_behind}').css('z-index')").to_i
  expect(front_z_index).to be > behind_z_index
end

Then(/^I set slider speed to medium/) do
  @browser.execute_script("__TestInterface.setSpeedSliderValue(0.8)")
end

Then(/^I slow down execution speed$/) do
  @browser.execute_script("Maze.scale.stepSpeed = 10;")
end

# Note: only works for levels other than the current one
Then(/^check that level (\d+) on this stage is done$/) do |level|
  undone = @browser.execute_script("return $('a[href$=\"level/#{level}\"].other_level').hasClass('level_undone')")
  !undone
end

# Note: only works for levels other than the current one
Then(/^check that level (\d+) on this stage is not done$/) do |level|
  undone = @browser.execute_script("return $('a[href$=\"level/#{level}\"].other_level').hasClass('level_undone')")
  undone
end

Then(/^I reload the page$/) do
  page_load(true) do
    @browser.navigate.refresh
  end
  wait_for_jquery
end

def wait_for_jquery
  wait_until do
    @browser.execute_script("return (typeof jQuery !== 'undefined');")
  rescue Selenium::WebDriver::Error::ScriptTimeOutError
    puts "execute_script timed out after 30 seconds, likely because this is \
Safari and the browser was still on about:blank when wait_for_jquery \
was called. Ignoring this error and continuing to wait..."
    false
  end
end

Then /^I wait for jquery to load$/ do
  wait_for_jquery
end

Then /^element "([^"]*)" is a child of element "([^"]*)"$/ do |child_id, parent_id|
  wait_short_until do
    @child_item = @browser.find_element(:id, child_id)
  end
  actual_parent_item = @child_item.find_element(:xpath, "..")
  actual_parent_id = actual_parent_item.attribute('id')
  expect(actual_parent_id).to eq(parent_id)
end

And(/^I set the language cookie$/) do
  params = {
    name: "_language",
    value: 'en'
  }

  if ENV['DASHBOARD_TEST_DOMAIN'] && ENV['DASHBOARD_TEST_DOMAIN'] =~ /\.code.org/ &&
      ENV['PEGASUS_TEST_DOMAIN'] && ENV['PEGASUS_TEST_DOMAIN'] =~ /\.code.org/
    params[:domain] = '.code.org' # top level domain cookie
  end

  @browser.manage.add_cookie params
end

And(/^I set the pagemode cookie to "([^"]*)"$/) do |cookie_value|
  params = {
    name: "pm",
    value: cookie_value
  }

  if ENV['DASHBOARD_TEST_DOMAIN'] && ENV['DASHBOARD_TEST_DOMAIN'] =~ /\.code.org/ &&
      ENV['PEGASUS_TEST_DOMAIN'] && ENV['PEGASUS_TEST_DOMAIN'] =~ /\.code.org/
    params[:domain] = '.code.org' # top level domain cookie
  end

  @browser.manage.add_cookie params
end

Given(/^I sign in as "([^"]*)"( and go home)?$/) do |name, home|
  navigate_to replace_hostname('http://studio.code.org/reset_session')
  user = @users[name]
  email = user[:email]
  password = user[:password]
  url = "/users/sign_in"
  browser_request(url: url, method: 'POST', body: {user: {login: email, password: password}})

  redirect = 'http://studio.code.org/home'
  navigate_to replace_hostname(redirect) if home
end

Given(/^I sign out and sign in as "([^"]*)"$/) do |name|
  steps %Q{
    And I sign in as "#{name}"
  }
end

Given(/^I sign in as "([^"]*)" from the sign in page$/) do |name|
  steps %Q{
    And check that the url contains "/users/sign_in"
    And I wait to see "#signin"
    And I fill in username and password for "#{name}"
    And I click "#signin-button"
    And I wait to see ".header_user"
  }
end

Given(/^I am a (student|teacher)( and go home)?$/) do |user_type, home|
  random_name = "Test#{user_type.capitalize} " + SecureRandom.base64
  steps %Q{
    And I create a #{user_type} named "#{random_name}"#{home}
  }
end

Given(/^I am enrolled in a plc course$/) do
  browser_request(url: '/api/test/enroll_in_plc_course', method: 'POST')
end

Given(/^I am assigned to script "([^"]*)"$/) do |script_name|
  browser_request(
    url: '/api/test/assign_script_as_student',
    method: 'POST',
    body: {script_name: script_name}
  )
end

Then(/^I fake completion of the assessment$/) do
  browser_request(url: '/api/test/fake_completion_assessment', method: 'POST', code: 204)
end

def generate_user(name)
  email = "user#{Time.now.to_i}_#{rand(1_000_000)}@test.xx"
  password = name + "password" # hack
  @users ||= {}
  @users[name] = {
    password: password,
    email: email
  }
  return email, password
end

And /^I check the pegasus URL$/ do
  pegasus_url = @browser.execute_script('return window.dashboard.CODE_ORG_URL')
  puts "Pegasus URL is #{pegasus_url}"
end

And /^I create a new section( and go home)?$/ do |home|
  section = JSON.parse(browser_request(url: '/dashboardapi/sections', method: 'POST', body: {login_type: 'email'}))
  section_code = section['code']
  @section_url = "http://studio.code.org/join/#{section_code}"
  navigate_to replace_hostname('http://studio.code.org') if home
end

And /^I create a new section with course "([^"]*)", version "([^"]*)"(?: and unit "([^"]*)")?$/ do |assignment_family, version_year, secondary|
  individual_steps %Q{
    When I see the section set up box
    When I press the new section button
    Then I should see the new section dialog

    When I select email login
    Then I wait to see "#uitest-assignment-family"

    When I select the "#{assignment_family}" option in dropdown "uitest-assignment-family"

    And I click selector "#assignment-version-year" once I see it
    And I click selector ".assignment-version-title:contains(#{version_year})" once I see it
  }

  if secondary
    individual_steps %Q{
      And I wait to see "#uitest-secondary-assignment"
      And I select the "#{secondary}" option in dropdown "uitest-secondary-assignment"
    }
  end

  individual_steps %Q{
    And I press the save button to create a new section
    And I wait for the dialog to close
    Then I should see the section table
  }
end

And /^I dismiss the language selector$/ do
  steps %Q{
    And I click selector ".close" if I see it
    And I wait until I don't see selector ".close"
  }
end

And(/^I give user "([^"]*)" authorized teacher permission$/) do |name|
  require_rails_env
  user = User.find_by_email_or_hashed_email(@users[name][:email])
  user.permission = UserPermission::AUTHORIZED_TEACHER
  user.save!
end

And(/^I create a(n authorized)? teacher-associated( under-13)? student named "([^"]*)"$/) do |authorized, under_13, name|
  steps "Given I create a teacher named \"Teacher_#{name}\""
  # enroll in a plc course as a way of becoming an authorized teacher
  steps 'And I am enrolled in a plc course' if authorized

  section = JSON.parse(browser_request(url: '/dashboardapi/sections', method: 'POST', body: {login_type: 'email'}))
  section_code = section['code']
  @section_url = "http://studio.code.org/join/#{section_code}"
  create_user(name, url: "/join/#{section_code}", code: 200, age: under_13 ? '10' : '16')
end

def sign_up(name)
  wait_proc = proc do
    opacity = @browser.execute_script <<JS
field = document.querySelector('#email-block > .error_in_field');
return field ? parseInt(window.getComputedStyle(field).opacity) : 0;
JS
    expect(opacity).to eq(0)
  end
  page_load(wait_proc: wait_proc) do
    steps %Q{
      And I click selector "#signup-button"
    }
  end
rescue RSpec::Expectations::ExpectationNotMetError
  tries ||= 0
  raise if (tries += 1) >= 5
  sleep 1

  email, _ = generate_user(name)
  steps %Q{
    And I type "#{email}" into "#user_email"
  }
  retry
end

# Call `execute_async_script` on the provided `js` code.
# Provides a workaround for Appium (mobile) which doesn't support execute_async_script on HTTPS.
# For Appium, wrap `execute_script` with a polling wait on a window variable that records the result.
def js_async(js, *args, callback_fn: 'callback', finished_var: 'window.asyncCallbackFinished')
  supports_async = !@browser.capabilities['mobile']
  if supports_async
    js = "var #{callback_fn} = arguments[arguments.length - 1];\n#{js}"
    @browser.execute_async_script(js, *args)
  else
    js = <<-JS
#{finished_var} = undefined;
var #{callback_fn} = function(result) { #{finished_var} = result; };
#{js}
    JS
    @browser.execute_script(js, *args)
    wait_short_until {@browser.execute_script("return #{finished_var};")}
  end
end

# Send an asynchronous XmlHttpRequest from the browser.
def browser_request(url:, method: 'GET', headers: {}, body: nil, code: 200, tries: 3)
  if body
    headers['Content-Type'] = 'application/x-www-form-urlencoded'
    body = "'#{body.to_param}'" if body
  end

  js = <<-JS
var xhr = new XMLHttpRequest();
xhr.open('#{method}', '#{url}', true);
#{headers.map {|k, v| "xhr.setRequestHeader('#{k}', '#{v}');"}.join("\n")}
var csrf = document.head.querySelector("meta[name='csrf-token']")
if (csrf) {
  xhr.setRequestHeader('X-Csrf-Token', csrf.content)
}
xhr.onreadystatechange = function() {
  if (xhr.readyState === 4) {
    callback(JSON.stringify({
      status: xhr.status,
      response: xhr.responseText
    }));
  }
};
xhr.send(#{body});
  JS
  Retryable.retryable(on: RSpec::Expectations::ExpectationNotMetError, tries: tries) do
    result = js_async(js)
    status, response = JSON.parse(result).slice('status', 'response').values
    expect(status).to eq(code), "Error code #{status}:\n#{response}"
    response
  end
end

def create_user(name, url: '/users.json', code: 201, **user_opts)
  navigate_to replace_hostname('http://studio.code.org/reset_session')
  Retryable.retryable(on: RSpec::Expectations::ExpectationNotMetError, tries: 3) do
    email, password = generate_user(name)
    browser_request(
      url: url,
      method: 'POST',
      body: {
        user: {
          user_type: 'student',
          email: email,
          password: password,
          password_confirmation: password,
          name: name,
          age: '16',
          terms_of_service_version: '1'
        }.merge(user_opts)
      },
      code: code
    )
  end
end

And(/^I create a (young )?student named "([^"]*)"( and go home)?$/) do |young, name, home|
  age = young ? '10' : '16'
  create_user(name, age: age)
  navigate_to replace_hostname('http://studio.code.org') if home
end

And(/^I create a student in the eu named "([^"]*)"$/) do |name|
  create_user(name,
    data_transfer_agreement_required: '1',
    data_transfer_agreement_accepted: '1'
  )
end

And(/^I create a teacher named "([^"]*)"( and go home)?$/) do |name, home|
  create_user(name, age: '21+', user_type: 'teacher', email_preference_opt_in: 'yes')
  navigate_to replace_hostname('http://studio.code.org') if home
end

And(/^I submit this level$/) do
  steps %Q{
    And I press "runButton"
    And I wait to see "#submitButton"
    And I press "submitButton"
    And I wait to see ".modal"
    And I press "confirm-button" to load a new page
  }
end

And(/^I get hidden script access$/) do
  browser_request(url: '/api/test/hidden_script_access', method: 'POST')
end

And(/^I save the section url$/) do
  section_code = @browser.execute_script <<-SCRIPT
    return document
      .querySelector('.uitest-owned-sections tbody tr:last-of-type td:nth-child(6)')
      .textContent
      .trim();
  SCRIPT
  @section_url = "http://studio.code.org/join/#{section_code}"
end

And(/^I navigate to the section url$/) do
  steps %Q{
    Given I am on "#{@section_url}"
  }
end

And(/^I wait until I am on the join page$/) do
  wait_short_until {/^\/join/.match(@browser.execute_script("return location.pathname"))}
end

# TODO: As of PR#9262, this method is not used. Evaluate its usage or lack
# thereof, removing it if it remains unused.
And(/I display toast "([^"]*)"$/) do |message|
  @browser.execute_script(<<-SCRIPT)
    var div = document.createElement('div');
    div.className = 'ui-test-toast';
    div.textContent = "#{message}";
    div.style.position = 'absolute';
    div.style.top = '50px';
    div.style.right = '50px';
    div.style.padding = '50px';
    div.style.backgroundColor = 'lightyellow';
    div.style.border = 'dashed 3px #eeee00';
    div.style.fontWeight = 'bold';
    div.style.fontSize = '14pt';
    document.body.appendChild(div);
  SCRIPT
end

And(/I fill in username and password for "([^"]*)"$/) do |name|
  steps %Q{
    And I type "#{@users[name][:email]}" into "#user_login"
    And I type "#{@users[name][:password]}" into "#user_password"
  }
end

And(/I fill in account email and current password for "([^"]*)"$/) do |name|
  steps %Q{
    And I type "#{@users[name][:email]}" into "#user_email"
    And I type "#{@users[name][:password]}" into "#user_current_password"
  }
end

And(/I type the section code into "([^"]*)"$/) do |selector|
  puts @section_url
  section_code = @section_url.split('/').last
  steps %Q{
    And I type "#{section_code}" into "#{selector}"
  }
end

When(/^I sign out$/) do
  if @browser.current_url.include?('studio')
    browser_request(url: replace_hostname('/users/sign_out.json'), code: 204)
    @browser.execute_script("sessionStorage.clear(); localStorage.clear();")
  else
    navigate_to replace_hostname('http://studio.code.org/reset_session')
  end
end

When(/^I am not signed in/) do
  steps 'element ".header_user:contains(Sign in)" is visible'
end

When(/^I debug cookies$/) do
  puts "DEBUG: url=#{CGI.escapeHTML @browser.current_url.inspect}"
  debug_cookies(@browser.manage.all_cookies)
end

When(/^I debug element "([^"]*)" text content$/) do |selector|
  text = @browser.execute_script("return $('#{selector}').text()")
  puts "element #{selector} text content: '#{text.to_s.strip}'"
end

When(/^I debug focus$/) do
  puts "Focused element id: #{@browser.execute_script('return document.activeElement.id')}"
end

When /^I debug channel id$/ do
  puts "appOptions.channel: #{@browser.execute_script('return (appOptions && appOptions.channel)')}"
end

And(/^I ctrl-([^"]*)$/) do |key|
  # Note: Safari webdriver does not support actions API
  @browser.action.key_down(:control).send_keys(key).key_up(:control).perform
end

def press_keys(element, key)
  element.send_keys(*convert_keys(key))
end

def convert_keys(keys)
  return keys[1..-1].to_sym if keys.start_with?(':')
  keys.gsub!(/([^\\])\\n/, "\\1\n") # Cucumber does not convert captured \n to newline.
  keys.gsub!(/\\\\n/, "\\n") # Fix up escaped newline
  # Convert newlines to :enter keys.
  keys.chars.map {|k| k == "\n" ? :enter : k}
end

# Known issue: IE does not register the key presses in this step.
# Add @no_ie tag to your scenario to skip IE when using this step.
And(/^I press keys "([^"]*)" for element "([^"]*)"$/) do |key, selector|
  element = @browser.find_element(:css, selector)
  press_keys(element, key)
end

When /^I press keys "([^"]*)"$/ do |keys|
  @browser.action.send_keys(*convert_keys(keys)).perform
end

# Press backspace repeatedly to clear an element.  Handy for React.
# Known issue: IE does not register the key presses in this step.
# Add @no_ie tag to your scenario to skip IE when using this step.
When /^I press backspace to clear element "([^"]*)"$/ do |selector|
  element = @browser.find_element(:css, selector)
  while @browser.execute_script("return $('#{selector}').val()") != ""
    press_keys(element, ":backspace")
  end
end

When /^I press enter key$/ do
  @browser.action.send_keys(:return).perform
end

When /^I press double-quote key$/ do
  @browser.action.send_keys('"').perform
end

When /^I press double-quote key for element "([^"]*)"$/ do |selector|
  press_keys(@browser.find_element(:css, selector), '"')
end

When /^I disable onBeforeUnload$/ do
  @browser.execute_script("window.__TestInterface.ignoreOnBeforeUnload = true;")
end

Then /^I get redirected away from "([^"]*)"$/ do |old_path|
  wait_short_until {!/#{old_path}/.match(@browser.execute_script("return location.pathname"))}
end

Then /^I get redirected away from the current page$/ do
  old_path = @browser.execute_script("return location.pathname")
  wait_short_until {!/#{old_path}/.match(@browser.execute_script("return location.pathname"))}
end

Then /^my query params match "(.*)"$/ do |matcher|
  wait_short_until {/#{matcher}/.match(@browser.execute_script("return location.search;"))}
end

Then /^I wait to see element with ID "(.*)"$/ do |element_id_to_seek|
  wait_short_until {@browser.find_element(id: element_id_to_seek)}
end

Then /^I get redirected to "(.*)" via "(.*)"$/ do |new_path, redirect_source|
  wait_short_until {/#{new_path}/.match(@browser.execute_script("return location.pathname"))}

  if redirect_source == 'pushState'
    state = {"modified" => true}
  elsif ['dashboard', 'none'].include? redirect_source
    state = nil
  end
  expect(@browser.execute_script("return window.history.state")).to eq(state)
end

last_shared_url = nil
Then /^I save the share URL$/ do
  wait_short_until {@button = @browser.find_element(id: 'sharing-input')}
  last_shared_url = @browser.execute_script("return document.getElementById('sharing-input').value")
end

When /^I open the share dialog$/ do
  Retryable.retryable(on: RSpec::Expectations::ExpectationNotMetError, sleep: 10, tries: 3) do
    steps <<-STEPS
      When I click selector ".project_share"
      And I wait to see a dialog titled "Share your project"
    STEPS
  end
end

When /^I navigate to the shared version of my project$/ do
  steps <<-STEPS
    When I open the share dialog
    And I navigate to the share URL
  STEPS
end

Then /^I navigate to the share URL$/ do
  steps <<-STEPS
    Then I save the share URL
    And I navigate to the last shared URL
  STEPS
end

Then /^I navigate to the last shared URL$/ do
  @browser.navigate.to last_shared_url
  wait_for_jquery
end

Then /^I navigate to the last shared URL with a queryparam$/ do
  @browser.navigate.to last_shared_url + '?testid=99999999'
  wait_for_jquery
end

Then /^I enter the last shared URL into input "(.*)"$/ do |selector|
  @browser.execute_script("document.querySelector('#{selector}').value = \"#{last_shared_url}\"")
end

Then /^I copy the embed code into a new document$/ do
  # Copy the embed code from the share dialog, which contains an iframe whose
  # source is a link to the embed version of this project. Wait for the iframe
  # to load, so that we can safely switch to it after this step completes.
  @browser.execute_script(
    %{
      document.body.innerHTML = $('#project-share textarea').text();
      $('iframe').load(function() {window.iframeLoadedForTesting = true;});
    }
  )
  wait_short_until {@browser.execute_script("return window.iframeLoadedForTesting;")}
end

Then /^I append "([^"]*)" to the URL$/ do |append|
  url = @browser.current_url + append
  @browser.navigate.to url
end

Then /^selector "([^"]*)" has class "(.*?)"$/ do |selector, class_name|
  item = @browser.find_element(:css, selector)
  classes = item.attribute("class")
  expect(classes.include?(class_name)).to eq(true)
end

Then /^selector "([^"]*)" doesn't have class "(.*?)"$/ do |selector, class_name|
  item = @browser.find_element(:css, selector)
  classes = item.attribute("class")
  expect(classes.include?(class_name)).to eq(false)
end

Then /^there is no horizontal scrollbar$/ do
  expect(@browser.execute_script('return document.documentElement.scrollWidth <= document.documentElement.clientWidth')).to eq(true)
end

# Place files in dashboard/test/fixtures
# Note: Safari webdriver does not support file uploads (https://code.google.com/p/selenium/issues/detail?id=4220)
Then /^I upload the file named "(.*?)"$/ do |filename|
  unless ENV['TEST_LOCAL'] == 'true'
    # Needed for remote (Sauce Labs) uploads
    @browser.file_detector = lambda do |args|
      str = args.first.to_s
      str if File.exist? str
    end
  end

  filename = File.expand_path(filename, '../fixtures')
  @browser.execute_script('$("input[type=file]").show()')
  element = @browser.find_element :css, '.uitest-hidden-uploader'
  element.send_keys filename
  @browser.execute_script('$("input[type=file]").hide()')

  unless ENV['TEST_LOCAL'] == 'true'
    @browser.file_detector = nil
  end
end

Then /^I scroll our lockable stage into view$/ do
  # use visible pseudo selector as we also have lock icons in (hidden) summary view
  wait_short_until {@browser.execute_script('return $(".fa-lock:visible").length') > 0}
  @browser.execute_script('$(".fa-lock:visible")[0].scrollIntoView(true)')
end

Then /^I open the stage lock dialog$/ do
  wait_for_jquery
  wait_short_until {@browser.execute_script("return $('.uitest-locksettings').length") > 0}
  @browser.execute_script("$('.uitest-locksettings').children().first().click()")
  wait_short_until {jquery_is_element_visible('.modal-body')}
end

Then /^I unlock the stage for students$/ do
  # allow editing
  @browser.execute_script("$('.modal-body button').first().click()")
  # save
  @browser.execute_script('$(".modal-body button:contains(Save)").first().click()')
end

Then /^I show stage answers for students$/ do
  @browser.execute_script("$('.modal-body button:contains(Show answers)').click()")
  @browser.execute_script('$(".modal-body button:contains(Save)").click()')
end

def refute_bad_gateway_or_site_unreachable
  first_header_text = @browser.execute_script("var el = document.getElementsByTagName('h1')[0]; return el && el.textContent;")
  expect(first_header_text).not_to end_with('Bad Gateway')
  # This error message is specific to Chrome
  expect(first_header_text).not_to eq('This site can’t be reached')
end

Then /^I wait until the image within element "([^"]*)" has loaded$/ do |selector|
  image_status_selector = "#{selector} div[data-image-status=loaded]"
  wait_until do
    @browser.execute_script("return $(#{image_status_selector.dump}).length > 0;")
  end
end

Then /^I wait until initial thumbnail capture is complete$/ do
  wait_until do
    @browser.execute_script('return dashboard.project.__TestInterface.isInitialCaptureComplete();')
  end
end

Then /^I wait for initial project save to complete$/ do
  wait_until do
    @browser.execute_script('return dashboard.project.__TestInterface.isInitialSaveComplete();')
  end
end

Then /^I save the timestamp from "([^"]*)"$/ do |css|
  @timestamp = @browser.find_element(css: css)['timestamp']
end

Then /^"([^"]*)" contains the saved timestamp$/ do |css|
  timestamp = @browser.find_element(css: css)['timestamp']
  expect(@timestamp).to eq(timestamp)
end

When /^I switch to text mode$/ do
  steps <<-STEPS
    When I press "show-code-header"
    And I wait to see Droplet text mode
  STEPS
end

When /^I see the section set up box$/ do
  steps 'When I wait to see ".uitest-set-up-sections"'
end

When /^I press the new section button$/ do
  steps <<-STEPS
    Given I scroll the ".uitest-newsection" element into view
    When I press the first ".uitest-newsection" element
  STEPS
end

Then /^I should see the new section dialog$/ do
  steps 'Then I see ".modal"'
end

When /^I select (picture|word|email) login$/ do |login_type|
  steps %Q{When I press the first ".uitest-#{login_type}Login" element}
end

When /^I press the save button to create a new section$/ do
  steps 'When I press the first ".uitest-saveButton" element'
end

When /^I wait for the dialog to close$/ do
  steps 'When I wait until element ".modal" is gone'
end

Then /^I should see the section table$/ do
  steps 'Then I see ".uitest-owned-sections"'
end

Then /^the section table should have (\d+) rows?$/ do |expected_row_count|
  wait_short_until {steps 'Then I should see the section table'}
  row_count = @browser.execute_script(<<-SCRIPT)
    return document.querySelectorAll('.uitest-owned-sections tbody tr').length;
  SCRIPT
  expect(row_count.to_i).to eq(expected_row_count.to_i)
end

Then /^the section table row at index (\d+) has (primary|secondary) assignment path "([^"]+)"$/ do |row_index, assignment_type, expected_path|
  link_index = (assignment_type == 'primary') ? 0 : 1
  href = @browser.execute_script(
    "return $('.uitest-owned-sections tbody tr:eq(#{row_index}) td:eq(3) a:eq(#{link_index})').attr('href');"
  )
  # ignore query params
  actual_path = href.split('?')[0]
  expect(actual_path).to eq(expected_path)
end

Then /^I save the section id from row (\d+) of the section table$/ do |row_index|
  @section_id = get_section_id_from_table(row_index)
end

Then /^the url contains the section id$/ do
  expect(@section_id).to be > 0
  expect(@browser.current_url).to include("?section_id=#{@section_id}")
end

Then /^the href of selector "([^"]*)" contains the section id$/ do |selector|
  href = @browser.execute_script("return $(\"#{selector}\").attr('href');")
  expect(@section_id).to be > 0

  # make sure the query params do not come after the # symbol
  expect(href.split('#')[0]).to include("?section_id=#{@section_id}")
end

Then /^the href of selector "([^"]*)" contains "([^"]*)"$/ do |selector, matcher|
  href = @browser.execute_script("return $(\"#{selector}\").attr('href');")
  expect(href).to include(matcher)
end

Then /^I navigate to teacher dashboard for the section I saved$/ do
  expect(@section_id).to be > 0
  steps %{
    Then I am on "http://studio.code.org/teacher_dashboard/sections/#{@section_id}"
  }
end

Then /^I navigate to the script "([^"]*)" stage (\d+) lesson extras page for the section I saved$/ do |script_name, stage_num|
  expect(@section_id).to be > 0
  steps %{
    Then I am on "http://studio.code.org/s/#{script_name}/stage/#{stage_num}/extras?section_id=#{@section_id}"
  }
end

Then /^I hide unit "([^"]+)"$/ do |unit_name|
  selector = ".uitest-CourseScript:contains(#{unit_name}) .fa-eye-slash"
  @browser.execute_script("$(#{selector.inspect}).click();")
  wait_short_until do
    @browser.execute_script("return window.__TestInterface && window.__TestInterface.toggleHiddenUnitComplete;")
  end
end

Then /^unit "([^"]+)" is marked as (not )?visible$/ do |unit_name, negation|
  selector = ".uitest-CourseScript:contains(#{unit_name})"
  visibility = @browser.execute_script("return $(#{selector.inspect}).attr('data-visibility');")
  expect(visibility).to eq(negation ? 'hidden' : 'visible')
end

# @return [Number] the section id for the corresponding row in the sections table
def get_section_id_from_table(row_index)
  # e.g. https://studio-code.org/teacher_dashboard/sections/54
  href = @browser.execute_script(
    "return $('.uitest-owned-sections tbody tr:eq(#{row_index}) td:eq(1) a').attr('href')"
  )
  section_id = href.split('/').last.to_i
  expect(section_id).to be > 0
  section_id
end

And /^element "([^"]*)" contains text matching "([^"]*)"$/ do |selector, regex_text|
  contents = @browser.execute_script("return $(#{selector.dump}).text();")
  expect(contents.match(regex_text).nil?).to eq(false)
end

Then /^I scroll the "([^"]*)" element into view$/ do |selector|
  @browser.execute_script("$('#{selector}')[0].scrollIntoView(true)")
end

Then /^I open the section action dropdown$/ do
  steps 'Then I click selector ".ui-test-section-dropdown" once I see it'
end

saved_url = nil
Then /^I save the URL$/ do
  saved_url = @browser.current_url
end

Then /^current URL is different from the last saved URL$/ do
  expect(@browser.current_url).not_to include(saved_url)
end

Then /^I navigate to the saved URL$/ do
  steps %Q{Then I am on "#{saved_url}"}
end

Then /^I sign out using jquery$/ do
  code = <<-JAVASCRIPT
    window.signOutComplete = false;
    function onSuccess() {
      window.signOutComplete = true;
    }
    $.ajax({
      url:'/users/sign_out',
      method: 'GET',
      success: onSuccess
    });
  JAVASCRIPT
  @browser.execute_script(code)
  wait_short_until {@browser.execute_script('return window.signOutComplete;')}
end

Then /^I open the Manage Assets dialog$/ do
  steps <<-STEPS
    Then I click selector ".settings-cog"
    And I click selector ".pop-up-menu-item"
  STEPS
end

Then /^page text does (not )?contain "([^"]*)"$/ do |negation, text|
  body_text = @browser.execute_script('return document.body && document.body.textContent;').to_s
  expect(body_text.include?(text)).to eq(negation.nil?)
end
