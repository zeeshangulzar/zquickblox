%w{
  airrecord
  redis
  ./airtable_con
  pdfcrowd
  byebug
  json
}.each { |r| require r }

@air_schools = []
@air_students = []
@air_student_choices = []
@uri = URI.parse("redis://redis-19094.c10.us-east-1-4.ec2.cloud.redislabs.com:19094")

puts "Starting at: #{Time.now}"

def get_save_local_data()
  schools()
  students()
  student_choices()
end

def generate_pdf(student, final_doc = "foobar.pdf")
  url_1 = "https://pdfgeneratorsite.herokuapp.com/page_1/#{student["Student ID"]}"
  url_2 = "https://pdfgeneratorsite.herokuapp.com/page_2/#{student["Student ID"]}"

  page_1 = "./PDFs/page_1_for_#{student["Student ID"]}.pdf"
  page_2 = "./PDFs/page_2_for_#{student["Student ID"]}.pdf"

  api = Pdfcrowd::HtmlToPdfClient.new("Roy_2019", "8c6663c893e88b7075f17b13802c9435")
  api.setPageWidth("17in")
  api.setPageHeight("11in")
  # api.setOrientation("landscape")
  api.convertUrlToFile(url_1, page_1)
  api.convertUrlToFile(url_2, page_2)

  `pdfunite #{page_1} #{page_2} #{final_doc}`
  `rm #{page_1} #{page_2} -f`

  puts final_doc
end

def process_students(student_ids = [])
  if student_ids && student_ids.count > 0
    @air_students = @air_students.select { |item| student_ids.include?(item["Student ID"]) }
  end

  @air_students.each_with_index do |student, index|
    begin
      redis = nil if redis
      redis = Redis.new(host: @uri.host, port: @uri.port, password: "9dw81cl47qVkOSpHyU8h0EW6D3G5JPTY")

      final_doc = "./PDFs/document_for_#{student["Student ID"]}.pdf"

      if File.file?(final_doc)
        # puts "EXISTS: #{student}"
        # puts final_doc
        redis = nil if redis
        next
      end

      student_choices_tmp = []
      student_choices_tmp = @air_student_choices.select { |item| item["Student ID"] == student["Student ID"] }

      student_choices_tmp = student_choices_tmp.first if student_choices_tmp && student_choices_tmp.count > 0

      next if student_choices_tmp && student_choices_tmp.count <= 0

      school_keys = []
      (1..6).each do |item|
        school_keys << student_choices_tmp["College Choice #{item} Key"]
      end

      next if school_keys && school_keys.count != 6

      selected_schools = []
      selected_schools = @air_schools.select { |item| school_keys.include?(item["SS_ID"]) }

      next if selected_schools && selected_schools.count != 6

      # puts school_keys.join(",")
      # puts "Schools: #{selected_schools.count}"

      redis.multi do
        redis.set("air_student", student.to_json)
        redis.set("air_student_choices", student_choices_tmp.to_json)
        redis.set("air_schools", selected_schools.to_json)
      end

      # puts redis.get("air_student")

      redis = nil
      # generate_pdf(student, final_doc)
      # break if index >= 0
      sleep(3)
    rescue => e
      redis = nil if redis
      puts e
      puts "ERROR with: #{student}"
      sleep(3)
    end
  end
end

get_save_local_data()
# process_students(["998125"])
process_students()

@air_schools = []
@air_students = []
@air_student_choices = []

puts "Done at: #{Time.now}"
