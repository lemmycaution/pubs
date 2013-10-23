module Kernel
  
  def called_from(level=1)
    arrs = caller((level||1)+1)  or return
    arrs[0] =~ /:(\d+)(?::in `(.*)')?/ ? [$`, $1.to_i, $2] : nil
  end

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
  end
  
end