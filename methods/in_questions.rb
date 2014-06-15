
# Process questions (array of structs)

def process_questions(service_name)
  $q_order.each do |key|
    if $verbose_mode == 1
      puts "Processing:\tValue for "+key
    end
    correct = 0
    if $q_struct[key].ask.match(/yes/)
      while correct != 1 do
        if $q_struct[key].value.match(/^get/)
          new_value            = $q_struct[key].value
          new_value            = eval"[#{new_value}]"
          $q_struct[key].value = new_value.join
        end
        if $use_defaults == 0
          question = $q_struct[key].question+"? [ "+$q_struct[key].value+" ] "
          print question
          answer = $stdin.gets.chomp
        else
          answer = $q_struct[key].value
          evaluate_answer(key,answer,service_name)
          correct = 1
        end
        if answer != ""
          if answer != $q_struct[key].value
            if $q_struct[key].valid.match(/[A-z|0-9]/)
              if $q_struct[key].valid.match(/#{answer}/)
                correct = evaluate_answer(key,answer)
                if correct == 1
                  $q_struct[key].value = answer
                end
              end
            else
              correct = evaluate_answer(key,answer,service_name)
              if correct == 1
                $q_struct[key].value = answer
              end
            end
          end
        else
          answer = $q_struct[key].value
          correct = evaluate_answer(key,answer,service_name)
          correct = 1
        end
      end
    else
      if $q_struct[key].value.match(/^get/)
        new_value            = $q_struct[key].value
        new_value            = eval"[#{new_value}]"
        $q_struct[key].value = new_value.join
      end
    end
  end
  return
end

# Code to check answers

def evaluate_answer(key,answer,service_name)
  correct = 1
  if $q_struct[key].eval != "no"
    new_value = $q_struct[key].eval
    if new_value.match(/^get|^set/)
      if new_value.match(/^get/)
        new_value = eval"[#{new_value}]"
        answer = new_value.join
        $q_struct[key].value = answer
      else
        $q_struct[key].value = answer
        eval"[#{new_value}]"
      end
      correct = 1
    else
      correct = eval"[#{new_value}]"
      if correct == 1
        $q_struct[key].value = answer
      end
    end
  end
  answer = answer.to_s
  if $verbose_mode == 1
    puts "Setting:\tParameter "+key+" to "+answer
  end
  return correct
end
