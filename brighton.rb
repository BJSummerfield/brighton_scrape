require 'selenium-webdriver'
require 'csv'
require './.env.rb'

@driver = Selenium::WebDriver.for :chrome
@wait = Selenium::WebDriver::Wait.new(timeout: 120)
@driver.manage.timeouts.implicit_wait = 20

def runner
  information_to_write = []
  user_name = USER_NAME
  company_id = COMPANY_ID
  password = PASSWORD 
  login(user_name, company_id, password)
  data_capture_test(information_to_write)
  write_file(information_to_write, './brighton_test.csv')
end

#**********
#Navigation
#**********

def login(user_name, company_id, password)
  @driver.get "https://www.brightonbest.com/#"
  add_input(@driver, :id, "custno", company_id)
  add_input(@driver, :id, "userid", user_name)
  add_input(@driver, :id, "password", password)
  click_element(@driver, :id, 'login')
end

def go_to_new_quote_page
  click_element(@driver, :id, 'btnNew')
  sleep(6)
  wait_element(@driver, :id, 'txtText1', "Quotation Spec")
end

def go_to_quotation_spec_page
  click_element(@driver, :id, 'QOspec')
  sleep(6)
  wait_element(@driver, :id, 'txtText1', "Quotation Spec")
end

def go_to_quotation_matched_page
  click_element(@driver, :id, 'QOmatched')
  sleep(6)
  wait_element(@driver, :id, 'txtText1', "Quotation Matched")
end

def go_to_shopping_cart_page
  click_element(@driver, :id, 'QOcart')
  sleep(6)
  wait_element(@driver, :id, 'txtText1', "Shopping Cart")
end

#************
#Data Capture
#************

# def data_capture(information_to_write)
#   go_to_new_quote_page
#   item_list_hash = build_item_list_hash
#   item_list_hash.each do |i, iv|
#     click_top_list(i.to_i)
#     sleep(0.25)
#     iv.each do |j, jv|
#       click_child_list(i.to_i, j.to_i)
#       sleep(0.25)
#       jv.each do |k|
#         click_checkbox(i.to_i, j.to_i, k.to_i)
#         item_scrape_runner(information_to_write)
#         click_checkbox(i.to_i, j.to_i, k.to_i)
#       end
#     end
#   end
# end

def data_capture_test(information_to_write)
  go_to_new_quote_page
  item_list_hash = Hash.new
  item_list_hash = build_item_list_hash
  item_list_hash.each do |i, iv|
    if i == '3'
      click_top_list(i.to_i)
      sleep(0.25)
      iv.each do |j, jv|
        if j == "2"
          click_child_list(i.to_i, j.to_i)
          sleep(0.25)
          jv.each do |k|
            if k == "0" || k == "3"
              click_checkbox(i.to_i, j.to_i, k.to_i)
              item_scrape_runner(information_to_write)
              click_checkbox(i.to_i, j.to_i, k.to_i)
            end
          end
        end
      end
    end
  end
  return information_to_write
end

def build_item_list_hash
  hash = Hash.new
   quote_li_array = select_child_elements(@driver, :class, 'dynatree-container')
  (quote_li_array.length).times do |i|
    hash["#{i}"] = {}
    expand_list(quote_li_array[i])
    child_li_array = select_child_elements(quote_li_array[i], :css, 'ul')
    (child_li_array.length).times do |j|
      expand_list(child_li_array[j])
      hash["#{i}"]["#{j}"] = []
      sub_child_li_array = select_child_elements(child_li_array[j], :css, 'ul')
      (sub_child_li_array.length).times do |k|
      hash["#{i}"]["#{j}"] << k.to_s
      end
    end
  end
  return hash
end

def item_scrape_runner(information_to_write)
  go_to_quotation_matched_page
  quotation_matched_loop(information_to_write)
  go_to_quotation_spec_page
  sleep(2) 
  return information_to_write
end

# def quotation_matched_loop_test
#   last_page = false
#   page_number_input = get_element(@driver, :class, "ui-pg-input")
#   2.times do 
#   # until last_page == true
#     increase_order_pkg_test
#     pages_class = get_pages_class
#     if pages_class.include?('ui-state-disabled')
#       last_page = true
#     end
#     if last_page == false
#       increase_quotation_matched_page_number(page_number_input)
#     end
#   end
# end

def quotation_matched_loop(information_to_write)
  last_page_number = get_element(@driver, :id, 'sp_1_pager').text.to_i
  last_page_number.times do |i|
    p i
    if i != 0
      go_to_quotation_matched_page
      sleep(2)
      page_number_input = get_element(@driver, :class, "ui-pg-input")
      increase_quotation_matched_page_number(page_number_input, (i-1))
      sleep(2)
      strike_out_quoted
      increase_quotation_matched_page_number(page_number_input, i)
      sleep(2)
    end
    increase_order_pkg
    go_to_shopping_cart_page
    scrape_table(information_to_write)
    go_to_quotation_spec_page
  end
  go_to_quotation_matched_page
  page_number_input = get_element(@driver, :class, "ui-pg-input")
  increase_quotation_matched_page_number(page_number_input, (last_page_number - 1))
  strike_out_quoted
  return information_to_write
end

def strike_out_quoted
  sleep(2)
  checkboxes = get_elements(@driver, :css, '[type="checkbox"]')
  rows = get_elements(@driver, :class, 'ui-row-ltr')
  (checkboxes.length).times do |i|
    checkboxes[i].click
    wait_strikethrough(rows, i)
  # ((checkboxes.length / 5).round).times do |i|
  #   checkboxes[i].click
  #   wait_strikethrough(element1, element2, i)
  end
  sleep(3)
end 

# def increase_order_pkg_test
#   hash = Hash.new
#   hash["bulk"] = reduce_inputs('[aria-describedby="grid_order_bulk"]')
#   hash["package"] = reduce_inputs('[aria-describedby="grid_order_package"]')
#   hash.each do |key, value|
#     ((value.length / 5).round).times do |i|
#       if value[i]
#         add_input(value[i], :class, 'mEdit', '1')
#         add_input(value[i], :class, 'mEdit', "\n")
#         wait_for_load(@driver, :id, 'Waiting_Dlg')
#       end
#     end
#   end
# end

def increase_order_pkg
  hash = Hash.new
  hash["bulk"] = reduce_inputs('[aria-describedby="grid_order_bulk"]')
  hash["package"] = reduce_inputs('[aria-describedby="grid_order_package"]')
  hash.each do |key, value|
    (value.length).times do |i|
      add_input(value[i], :class, 'mEdit', '1')
      add_input(value[i], :class, 'mEdit', "\n")
      wait_for_load(@driver, :id, 'Waiting_Dlg')
    end
  end
end

def increase_quotation_matched_page_number(page_number_input, index)
  page_number = page_number_input.attribute('value')
  page_number_input.clear
  add_input(@driver, :class, 'ui-pg-input', (index + 1))
  add_input(@driver, :class, 'ui-pg-input', "\n")
end

def scrape_table(information_to_write)
  table_rows = shopping_cart_table_rows
  table_loop(table_rows, information_to_write)
  return information_to_write
end

def table_loop(table_rows, information_to_write)
  i = 0
  (table_rows.length / 2).times do
    first_row = table_rows[i]
    second_row = table_rows[i + 1] 
    item_hash = scrape_row(first_row, second_row)
    if check_inventory(item_hash)
      information_to_write << item_hash
    end
    i += 2
  end
  return information_to_write
end

def scrape_row(first_row, second_row)
  hash = Hash.new
  hash['Part Number'] = get_element(second_row, :css, 'span').text
  hash['Description'] = get_element(first_row, :class, 'divitmdesc').text
  hash['Pack-Size'] = get_element(first_row, :class, 'ordqty').attribute('value')
  hash['Weight'] = get_element(first_row, :class, 'spantxtWeight').text
  hash['Cost'] = get_element(first_row, :class, 'spantxtAmount').text
  hash['Stock'] = check_stock(second_row)
  return hash
end

def check_stock(second_row)
  stock_message = get_element(second_row, :class, 'divStockInfo').text
  return stock_message if stock_message == "In Stock"
  return "Out of Stock" if stock_message.include?('Check Alternative Warehouse')
  return nil  
end

def check_inventory(item)
  if item["Stock"] == nil
    return false
  end
  return true
end

def write_file(file, filename)
  CSV.open(filename, 'wb') do |csv|
    array = []
    file[0].each do |k,v|
      array << k
    end
    csv << array
    file.each do |item|
      array = []
      item.each do |k,v|  
        array << v
      end
      csv << array
    end
  end
end

#****************
#Selectors
#****************

def reduce_inputs(selector_name)
  get_elements(@driver, :css, selector_name).reduce([]) do |memo, element|
    if @driver.execute_script("return arguments[0].childElementCount" , element) > 0
      memo << element
    end
    memo
  end
end

def click_top_list(i)
  quote_li_array = select_child_elements(@driver, :class, 'dynatree-container')
  expand_list(quote_li_array[i])
end

def click_child_list(i, j)
  quote_li_array = select_child_elements(@driver, :class, 'dynatree-container')
  child_li_array = select_child_elements(quote_li_array[i], :css, 'ul')
  expand_list(child_li_array[j])
end

def click_checkbox(i,j,k)
  quote_li_array = select_child_elements(@driver, :class, 'dynatree-container')
  child_li_array = select_child_elements(quote_li_array[i], :css, 'ul')
  sub_child_li_array = select_child_elements(child_li_array[j], :css, 'ul')
  click_element(sub_child_li_array[k], :class, 'dynatree-checkbox')
end

def expand_list(element)
  click_element(element, :class, 'dynatree-expander')
end

def shopping_cart_table_rows
  full_table = get_element(@driver, :css, 'tbody')
  table_rows = get_elements(full_table, :class, 'ui-widget-content')
  return table_rows
end

def get_pages_class
  pages = get_element(@driver, :id, 'next_pager')
  pages_class = pages.attribute('class')
  return pages_class
end

def select_child_elements(instance, selector, selector_name)
  parent = get_element(instance, selector, selector_name)
  child_array = @driver.execute_script("return arguments[0].childNodes" , parent)
  return child_array
end

def click_element(instance, selector, selector_name)
  element = @wait.until {
    element = instance.find_element(selector, selector_name)
    element if element.displayed?
  }
  element.click
end

def get_element(instance, selector, selector_name)
  element = @wait.until {
    element = instance.find_element(selector, selector_name)
    element if element != nil
  }
  return element
end

def get_elements(instance, selector, selector_name)
  elements = @wait.until {
    elements = instance.find_elements(selector, selector_name)
    elements if elements != []
  }
  return elements
end

def add_input(instance, selector, selector_name, input)
  element = @wait.until {
    element = instance.find_element(selector, selector_name)
    element if element.displayed?
  }
  element.send_keys(input)
end

def wait_for_load(instance, selector, selector_name)
  @wait.until {
    element = instance.find_element(selector, selector_name)
    element if !element.displayed?
  }
end

def wait_element(instance, selector, selector_name, matched_text)
    element = @wait.until {
    element = instance.find_element(selector, selector_name)
    element if element.displayed? && element.text == matched_text
  }
  return 
end

def wait_strikethrough(rows, i)
  @wait.until {
    element = get_element(rows[i], :css, '[disabled="disabled"]')
    return if element != nilKB  
  } 
end  
runner


#capture the input boxes after elements in wati strikethrough

