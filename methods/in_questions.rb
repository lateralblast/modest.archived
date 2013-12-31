
# Process questions (array of structs)

def process_questions(q_struct,q_order)
  puts ""
  q_order.each do |key|
    correct=0
    while correct != 1 do
      if q_struct[key].value.match(/^get/)
        new_value=q_struct[key].value
        new_value=eval"[#{new_value}]"
        q_struct[key].value=new_value.join
      end
      if $use_defaults == 0
        print q_struct[key].question+"? [ "+q_struct[key].value+" ] "
        answer=gets.chomp
      else
        answer=q_struct[key].value
        if $verbose_mode == 1
          puts "Setting:\t"+key+" to "+answer
        end
        correct=1
      end
      if answer != ""
        if answer != q_struct[key].value
          if q_struct[key].valid.match(/[A-z|0-9]/)
            if q_struct[key].valid.match(/#{answer}/)
              (correct,q_struct)=evaluate_answer(q_struct,q_order,key,answer)
              if correct == 1
                q_struct[key].value=answer
              end
            end
          else
            (correct,q_struct)=evaluate_answer(q_struct,q_order,key,answer)
            if correct == 1
              q_struct[key].value=answer
            end
          end
        end
      else
        answer=q_struct[key].value
        (correct,q_struct)=evaluate_answer(q_struct,q_order,key,answer)
        correct=1
      end
    end
  end
  return q_struct
end

# Code to check answers

def evaluate_answer(q_struct,q_order,key,answer)
  correct=1
  if q_struct[key].eval != "no"
    new_value=q_struct[key].eval
    if new_value.match(/^get|^set/)
      if new_value.match(/^get/)
        new_value=eval"[#{new_value}]"
        answer=new_value
        q_struct[key].value=answer
      else
        q_struct[key].value=answer
        q_order=eval"[#{new_value}]"
      end
      correct=1
    else
      correct=eval"[#{new_value}]"
      if correct == 1
        q_struct[key].value=answer
      end
    end
  end
  answer=answer.to_s
  if $verbose_mode == 1
    puts "Setting:\tParameter"+key+" to "+answer
  end
  return correct,q_struct
end
