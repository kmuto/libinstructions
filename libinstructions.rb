# encoding: utf-8
# IDGXML処理支援ライブラリ
#  Copyright 2008-2016 Kenshi Muto <kmuto@debian.org>
#
# ソフトウェア使用許諾同意書
# 本ソフトウェアの利用・変更・再配布にあたっては、下記の使用許諾同意書に
# 同意する必要があります。
# 
# 1. 本使用許諾同意書における「ソフトウェア」とは、機械可読の資料 (ライブ
#    ラリ、スクリプト、ソースファイル、データファイル)、実行形式、および
#    文書を意味します。
# 2. 本ソフトウェアの使用許諾同意書に同意する限りにおいて、使用者は
#    本ソフトウェアを自由に利用、変更することができます。
# 3. 本ソフトウェアに変更を加えない限りにおいて、使用者は本ソフトウェアを
#    自由にコピー、再配布することができます。
# 4. 本ソフトウェアは無保証です。作者およびそれに関連する組織、配布者は、
#    本ソフトウェアの使用に起因する一切の直接損害、間接損害、偶発的損害、
#    特別損害、懲戒的損害、派生的損害について何らの責任・保証も負いません。
# 5. 本ソフトウェアを変更した上で再配布するときには、下記の事項すべてに
#    従わなければなりません。
#    - 使用許諾同意書の内容に変更を加えてはなりません。技術上の理由で
#      文字エンコーディングの変換を行うことは許可しますが、その使用者が
#      特殊な技術的措置なしに可読な形でなければなりません。
#    - 技術上の理由でバイナリ化・難読化を行う場合も、変更箇所を含めた
#      ソフトウェアを、その使用者が可読可能な形式の形で同一のメディアで
#      提供しなければなりません。本使用許諾同意書の2条および3条により、
#      使用者が可読形式の該当ソフトウェアを変更、コピー、再配布することを
#      妨げてはなりません。
#    - ソフトウェア構成物の所定の作者名の欄に、変更者のクレジット
#      (個人名、企業名、所属、連絡先など)を「追加」しなければなりません。
# 6. 本ソフトウェアを変更した上で再配布するときには、変更理由および
#    その内容を明記することが推奨されます。
# 7. 使用者がソフトウェアに適用可能な特許に対して特許侵害にかかわる何らか
#    の行動を開始した時点で、この使用許諾同意書は自動的に終了し、以降
#    使用者はこの使用許諾書によって与えられた一切の権利を放棄するものと
#    します。
# 
# 著作権所有者 Copyright (C) 2008-2016 Kenshi Muto. All rights reserved.
# 使用許諾同意書バージョン1.0
# 著作権所有者による書面での事前の許可がない限り、この使用許諾同意書
# に変更を加えてはなりません。

$KCODE = 'u' if RUBY_VERSION < "1.9"
require 'rexml/document'
include REXML

def get_zenhan_size(s)
  # 全角2半角1の文字数で数える
  s.each_char.map {|c| c.bytesize == 1 ? 1 : 2}.reduce(0, &:+)
end


def unescape(text)
  # エスケープを元に戻す
  text.gsub("&lt;", "<").gsub("&gt;", ">").gsub("&quot;", "\"").gsub("&amp;", "&")
end

def maru(num)
  # 丸数字
  %w(① ② ③ ④ ⑤ ⑥ ⑦ ⑧ ⑨ ⑩ ⑪ ⑫ ⑬ ⑭ ⑮ ⑯ ⑰ ⑱ ⑲ ⑳ ㉑ ㉒ ㉓ ㉔ ㉕ ㉖ ㉗ ㉘ ㉙ ㉚ ㉛ ㉜ ㉝ ㉞ ㉟)[num.to_i - 1]
end

def kuromaru(num)
  # 黒丸数字
  %w(❶ ❷ ❸ ❹ ❺ ❻ ❼ ❽ ❾ ❿ ⓫ ⓬ ⓭ ⓮ ⓯ ⓰ ⓱ ⓲ ⓳ ⓴)[num.to_i - 1]
end

def insert_before(e, ename, attributes, text)
  # 要素eの前にenameという名前の要素を属性ハッシュattributes、内容textで作成する
  # ただし、enameが空のときにはtextの内容をテキストとして挿入する
  # enameが?のときにはインストラクションと見なしてattributesハッシュの最初のキー/値ペアをインストラクションの内容とする
  if ename == ""
    # RAWテキスト
    e.parent.insert_before(e, Text.new(text, true))
  elsif ename == "?"
    # XMLインストラクション
    e.parent.insert_before(e, Instruction.new(attributes.keys[0], attributes.values[0]))
  else
    # 要素
    e.parent.insert_before(e, Element.new(ename))
    unless attributes.nil?
      attributes.keys.each do |a|
        e.previous_sibling.attributes[replace_common_name(a)] = attributes[a]
      end
    end
    unless text.nil?
      e.previous_sibling.text = text
      e.previous_sibling[0].raw = true
    end
  end
end

def insert_first(e, ename, attributes, text)
  # 要素eのブロックの最初にenameという名前の要素を属性ハッシュattributes、内容textで作成する
  # ただし、enameが空のときにはtextの内容をテキストとして挿入する
  # enameが?のときにはインストラクションと見なしてattributesハッシュの最初のキー/値ペアをインストラクションの内容とする
  if e.size == 0
    # 要素内が空ならinsert_afterを使う
    return insert_last(e, ename, attributes, text)
  end
  if ename == ""
    # RAWテキスト
    e.insert_before(e[0], Text.new(text, true))
  elsif ename == "?"
    # XMLインストラクション
    e.insert_before(e[0], Instruction.new(attributes.keys[0], attributes.values[0]))
  else
    # 要素
    e.insert_before(e[0], Element.new(ename))
    unless attributes.nil?
      attributes.keys.each do |a|
        e[0].attributes[replace_common_name(a)] = attributes[a]
      end
    end
    unless text.nil?
      e[0].text = text
      e[0][0].raw = true
    end
  end
end

def insert_after(e, ename, attributes, text)
  # 要素eの後にenameという名前の要素を属性ハッシュattributes、内容textで作成する
  # ただし、enameが空のときにはtextの内容をテキストとして挿入する
  # enameが?のときにはインストラクションと見なしてattributesハッシュの最初のキー/値ペアをインストラクションの内容とする
  if ename == ""
    # RAWテキスト
    e.parent.insert_after(e, Text.new(text, true))
  elsif ename == "?"
    # XMLインストラクション
    e.parent.insert_after(e, Instruction.new(attributes.keys[0], attributes.values[0]))
  else
    # 要素
    e.parent.insert_after(e, Element.new(ename))
    unless attributes.nil?
      attributes.keys.each do |a|
        e.next_sibling.attributes[replace_common_name(a)] = attributes[a]
      end
    end
    unless text.nil?
      e.next_sibling.text = text
      e.next_sibling[0].raw = true
    end
  end
end

def insert_last(e, ename, attributes, text)
  # 要素eのブロックの最後にenameという名前の要素を属性ハッシュattributes、内容textで作成する
  # ただし、enameが空のときにはtextの内容をテキストとして挿入する
  # enameが?のときにはインストラクションと見なしてattributesハッシュの最初のキー/値ペアをインストラクションの内容とする
  if ename == ""
    # RAWテキスト
    e.add_text(Text.new(text, true))
  elsif ename == "?"
    # XMLインストラクション
    e.insert_after(e[e.size - 1], Instruction.new(attributes.keys[0], attributes.values[0]))
  else
    # 要素
    e2 = e.add_element(ename)
    unless attributes.nil?
      attributes.keys.each do |a|
        e2.attributes[replace_common_name(a)] = attributes[a]
      end
    end
    unless text.nil?
      e2.text = text
      e2[0].raw = true
    end
  end
end

def replace_common_name(a)
  # 属性名pstyleとcstyleにaid:を付ける
  a = "aid:" + a if a == "pstyle" || a == "cstyle"
  return a
end

def remove_lf(e)
  # e要素内のブロックの最後の要素がテキストなら、最後の\nを削除する
  if e.size > 0 && e[e.size - 1].instance_of?(Text)
    e[e.size - 1] = Text.new(e[e.size - 1].to_s.chomp, true)
    e[e.size - 1].raw = true
  end
end

def in_block?(e, array)
  # 指定の要素がarray配列で示される要素名ブロックの中に含まれているかどうかを調べる。含まれていたらelement自身を、いなければnilを返す
  while e != e.root
    return true if array.include?(e.parent.name)
    e = e.parent
  end
  return nil
end

def is_previous_lf?(e, tags)
  # e要素の前の要素がtags配列のいずれかの場合にtrueを返す
  return nil if e.previous_sibling == nil
  if e.previous_sibling.instance_of?(Element)
    return true if !tags.nil? && tags.include?(e.previous_sibling.name)
    return nil
  elsif e.previous_sibling.instance_of?(Text)
    if e.previous_sibling == "\n"
      return is_previous_lf?(e.previous_sibling, tags)
    else
      return nil
    end
  elsif e.previous_sibling.instance_of?(Instruction)
    # インストラクションの場合には前を探す
    return is_previous_lf?(e.previous_sibling, tags)
  else
    return nil
  end
end

def previous_element(e)
  # eの前の要素名を返す
  return nil if e.previous_sibling.nil?
  if e.previous_sibling.instance_of?(Element)
    return e.previous_sibling.name
  else
    return previous_element(e.previous_sibling)
  end
end

def previous_element2(e)
  # eの前の要素名と要素自体を返す
  return nil, nil if e.previous_sibling.nil?
  if e.previous_sibling.instance_of?(Element)
    return e.previous_sibling.name, e.previous_sibling
  else
    return previous_element2(e.previous_sibling)
  end
end

def next_element(e)
  # eの次の要素名を返す。インストラクションやテキストであればさらに次のノードを探す
  return nil if e.next_sibling.nil?
  if e.next_sibling.instance_of?(Element)
    return e.next_sibling.name
  else
    return next_element(e.next_sibling)
  end
end

def next_element2(e)
  # eの次の要素名と要素自体を返す
  return nil, nil if e.next_sibling.nil?
  if e.next_sibling.instance_of?(Element)
    return e.next_sibling.name, e.next_sibling
  else
    return next_element2(e.next_sibling)
  end
end

def pS(e, value)
  # 段落スタイルのショートカット
  e.attributes["aid:pstyle"] = value
end

def cS(e, value)
  # 文字スタイルのショートカット
  e.attributes["aid:cstyle"] = value
end

def oS(e, value)
  # オブジェクトスタイルのショートカット
  e.attributes["ostyle"] = value
end

def tS(e, value)
  # 表スタイルのショートカット
  e.attributes["aid5:tablestyle"] = value
end

def eS(e, value)
  # 表セルスタイルのショートカット
  e.attributes["aid5:cellstyle"] = value
end

def shrink_forward_lf(e)
  # 空行のTextオブジェクトが前方向から連続するときにシュリンクする
  if !e.nil? && !e.next_sibling.nil? && e.next_sibling.instance_of?(Text) && e.next_sibling.to_s == "\n"
    shrink_forward_lf(e.next_sibling)
    e.next_sibling.remove
  end
end

def shrink_backward_lf(e)
  # 空行のTextオブジェクトが後ろ方向から連続するときにシュリンクする
  if !e.nil? && !e.previous_sibling.nil? && e.previous_sibling.instance_of?(Text) && e.previous_sibling.to_s == "\n"
    shrink_backward_lf(e.previous_sibling)
    e.previous_sibling.remove
  end
end

def move_tree(frome, toe)
  # 要素fromeの全子要素をtoeに移動し、fromeを削除する
  source = []
  frome.each_child {|e2|
    source.push(e2)
  }
  source.each {|s|
    toe.insert_after(frome, s)
  }
  frome.remove
end

def find_previous_element(element)
  # 1つ前の要素が見つかるまで探す。最終的に見つからなかった場合はnilを返す
  return nil if element.nil?
  return element if element.instance_of?(Element)
  return find_previous_element(element.previous_sibling)
end

def find_next_element(element)
  # 1つ次の要素が見つかるまで探す。最終的に見つからなかった場合はnilを返す
  return nil if element.nil?
  return element if element.instance_of?(Element)
  return find_next_element(element.next_sibling)
end

def move_tree_in_previous_element(frome, newname)
  # 要素fromeの全子要素を1つ前の要素内に移動する。newnameがnil以外のときにはnewnameの名前の要素を作り、そこに移動する
  e = find_previous_element(frome.previous_sibling)
  raise "There isn't any previous elements." if e.nil?
  if newname.nil?
    move_tree(frome, e)
  else
    insert_last(e, newname, {}, nil)
    move_tree(frome, e[e.size - 1])
  end
end

def handle_nest(doc)
  # リストブロック用に、要素doc直下にある最初の要素を展開する
  parent = doc.parent
  source = []
  doc.each_child do |e|
    source.push(e)
  end
  source.reverse.each do |s|
    parent.insert_after(doc, s)
  end
  doc.remove

  shrink_backward_lf(parent[parent.size - 1])
end

def append_lf(e)
  # 後ろに改行を追加する
  if e.next_sibling.nil? || e.next_sibling.instance_of?(Element)
    insert_after(e, "", nil, "\n")
  elsif e.next_sibling.instance_of?(Instruction)
    append_lf(e.next_sibling)
  end
end

def handle_list_block(e, array)
  # e要素の後にあるものを、
  # - テキスト要素
  # - インストラクション
  # - inlist属性のあるもの
  # - arrayに含まれるもの
  # であれば移動する

  if !e.next_sibling.nil?
    if e.next_sibling.instance_of?(Text) || e.next_sibling.instance_of?(Instruction)
      e.add(e.next_sibling)
      handle_list_block(e, array)
    elsif e.next_sibling.instance_of?(Element)
      if !e.next_sibling.attributes["inlist"].nil?
        e.add(e.next_sibling)
        handle_list_block(e, array)
      elsif array.include?(e.next_sibling.name)
        e.add(e.next_sibling)
        handle_list_block(e, array)
      elsif e.name == e.next_sibling.name && !e.next_sibling.elements[1, "li"].nil?
        if e.next_sibling.elements[1, "li"].attributes["num"].to_i > 1 || e.name == "ul"
          # 隣に同じ名前の要素がある場合はこちらの要素内に格納する
          handle_list_block(e.next_sibling, array)
          source = []
          e.next_sibling.each_child {|ec|
            source.push(ec)
          }
          source.each {|s|
            e.add(s)
          }
          e.next_sibling.remove
        end
      end
    end
  end
end

def LF
  Text.new("\n")
end

def is_lf?(e)
  # LFかどうかを返す
  if !e.nil? && e.instance_of?(Text) && e == "\n"
    return true
  end
  return nil
end

def get_dtp(e)
  # eの要素位置にあるdtpインストラクションの値を返す。なければnilを返す
  if !e.nil? && e.instance_of?(Instruction) && e.target == "dtp"
    return e.content
  else
    return nil
  end
end

def end_of_block?(e, array)
  # eがarray範囲の親要素ブロックの最後の要素かどうかを調べ、要素であればtrue、そうでなければnilを返す
  if !e.nil? && e.instance_of?(Element)
    array.each do |pe|
      if e.parent.name == pe
        (e.parent.size - 1).to_i.downto(0) do |i|
          return true if e.parent[i] == e
          next if e.parent[i].instance_of?(Text) && e.parent[i] == "\n"
          break
        end
      end
    end
  end
  return nil
end

def back_ent(s)
  # &lt;, &gt;, &amp; を戻す
  s.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&amp;', '&')
end

def set_cell_attributes(e)
  # <?dtp table ... ?>命令で指定されたalign、rowspan、colspan、celltypeをセルに適用する
  if get_dtp(e[0]) =~ /table/
    get_dtp(e[0]).sub(/\Atable /, '').split(/\s*,\s*/).each do |item|
      k, v = item.split('=')
      e.attributes['celltype'] = v if k == 'type'
      if k == 'align'
        e.attributes['align'] = v
      end
      if k == 'rowspan'
        e.attributes['rowspan'] = v
        e.attributes['a_rowspan'] = v
      end
      if k == 'colspan'
        e.attributes['colspan'] = v
        e.attributes['a_colspan'] = v
      end
    end
  end
end

alias :insertBefore :insert_before
alias :insertFirst :insert_first
alias :insertLast :insert_last
alias :insertAfter :insert_after
alias :removeLF :remove_lf
alias :inBlock? :in_block?
alias :isPreviousLF? :is_previous_lf?
alias :previousElement :previous_element
alias :previousElement2 :previous_element2
alias :nextElement :next_element
alias :nextElement2 :next_element2
alias :shrinkForwardLF :shrink_forward_lf
alias :shrinkBackwardLF :shrink_backward_lf
alias :moveTree :move_tree
alias :findPreviousElement :find_previous_element
alias :findNextElement :find_next_element
alias :moveTreeInPreviousElement :move_tree_in_previous_element
alias :handleNest :handle_nest
alias :appendLF :append_lf
alias :handleListBlock :handle_list_block
alias :isLF? :is_lf?
alias :getDTP :get_dtp
alias :endOfBlock? :end_of_block?
alias :backEnt :back_ent
