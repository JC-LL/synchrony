module InfoDisplay
  def info(level,str,other="")
    case level
    when 0
      space_bar=""
    when 1
      space_bar=" |-"
    else
      space_bar=" "*3*(level-1)+" |-"
    end
    str="#{space_bar}[+] #{str}"
    other="#{other}"
    if other.size > 0
      puts str.ljust(40,'.')+" #{other}"
    else
      puts str
    end
  end

  def hit_a_key str=""
    puts str
    puts "hit_a_key"
    $stdin.gets
  end
end

if $PROGRAM_NAME==__FILE__
  include InfoDisplay
  info 0,"I"
  info 1,"A"
  info 2,"1"
  info 1,"B"
  info 2,"1"
  info 2,"2"
  info 2,"3"
  info 3,"a"
end
