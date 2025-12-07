
require 'liquid'

class SpintaxTest
  def call(message)
    process_liquid_in_content({}, message)
  end

  def process_liquid_in_content(drops, message)
    message = message.gsub(/`(.*?)`/m, '{% raw %}`\\1`{% endraw %}')
    template = Liquid::Template.parse(message)
    rendered_content = template.render(drops)
    puts "Rendered Liquid: #{rendered_content}"
    process_spintax(rendered_content)
  rescue Liquid::Error => e
    puts "Liquid Error: #{e.message}"
    message
  end

  def process_spintax(text)
    loop do
      new_text = text.gsub(/\{([^{}]*)\}/) { Regexp.last_match(1).split('|').sample }
      break if new_text == text

      text = new_text
    end
    text
  end
end

puts "Test 1: {Hello|Hi}"
puts SpintaxTest.new.call("{Hello|Hi}")

puts "\nTest 2: Hello {World|There}"
puts SpintaxTest.new.call("Hello {World|There}")

puts "\nTest 3: Nested? {{A|B}|C}"
puts SpintaxTest.new.call("{{A|B}|C}")

puts "\nTest 4: With Liquid: {{ 'Variables' }}"
puts SpintaxTest.new.call("{{ 'Variables' }} {Spintax|Works}")
