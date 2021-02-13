module InfoPrinter
  def info level,message
    head = (level==0) ? "[+] " : "|--[+] "
    case level
    when 0
      shift=0
    when 1
      shift=1
    else
      level_=(level<0) ? 1 : level
      shift=1+(level_-1)*4
    end
    space=" "*shift
    puts space+head+message unless level < 0
  end
end
