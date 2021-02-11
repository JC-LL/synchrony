module InfoPrinter
  def info level,message
    head = (level==0) ? "[+] " : "|--[+] "
    case level
    when 0
      shift=0
    when 1
      shift=1
    else
      shift=1+(level-1)*4
    end
    space=" "*shift
    puts space+head+message
  end
end
