# -*- coding: utf-8 -*-
# HTML処理支援ライブラリ
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

def get_dtp(e)
  # eの要素位置にあるdtpインストラクションの値を返す。なければnilを返す
  if !e.nil? && e.instance_of?(Instruction) && e.target == "dtp"
    return e.content
  else
    return nil
  end
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
      end
      if k == 'colspan'
        e.attributes['colspan'] = v
      end
    end
    e[0].remove
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

def insert_before(e, ename, attributes, text)
  # 要素eの前にenameという名前の要素を属性ハッシュattributes、内容textで作成する
  # ただし、enameが空のときにはtextの内容をテキストとして挿入する
  # enameが?のときにはインストラクションと見なしてattributesハッシュの最初のキー/値ペアをインストラクションの内容とする
  if ename == ""
    e.parent.insert_before(e, Text.new(text, true))
  elsif ename == "?"
    e.parent.insert_before(e, Instruction.new(attributes.keys[0], attributes.values[0]))
  else
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
    return insert_last(e, ename, attributes, text)
  end
  if ename == ""
    e.insert_before(e[0], Text.new(text, true))
  else
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
    e.parent.insert_after(e, Text.new(text, true))
  else
    e.parent.insert_after(e, Element.new(ename))
    unless attributes.nil?
      attributes.keys.each {|a|
        e.next_sibling.attributes[replace_common_name(a)] = attributes[a]
      }
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
    e.add_text(Text.new(text, true))
  else
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

def next_element2(e)
  # eの次の要素名と要素自体を返す
  return nil, nil if e.next_sibling.nil?
  if e.next_sibling.instance_of?(Element)
    return e.next_sibling.name, e.next_sibling
  else
    return next_element2(e.next_sibling)
  end
end

def replace_common_name(a)
  # 用意したけどダミー
  a
end

def check_attrs(target, testcase)
  # 属性があるかを確認する
  return true if testcase == nil
  testcase.each_pair do |k, v|
    return false if target[k] != v
  end
  return true
end

def check_attrs2(targete, array)
  # arrayに含まれていることは確認済みだが属性を確認していない
  array.each do |a|
    if a.keys[0] == targete.name
      testcase = a.values[0]
      return true if testcase == {}
      testcase.each_pair do |k, v|
        return true if targete.attributes[k] == v
      end
    end
  end
  return false
end

def handle_list_block_with_array(e, array)
  # e要素の後にあるものを、
  # - テキスト要素
  # - インストラクション
  # - inlist属性のあるもの
  # - arrayに含まれるもの
  # であれば移動する
  if e.next_sibling.instance_of?(Text) || e.next_sibling.instance_of?(Instruction)
    e.add(e.next_sibling)
    handle_list_block_with_array(e, array)
  elsif e.next_sibling.instance_of?(Element)
 
    targetelements = []
    array.each do |a|
      targetelements.push(a.keys[0])
    end

    if !e.next_sibling.attributes["inlist"].nil?
      e.next_sibling.attributes.delete("inlist")
      e.add(e.next_sibling)
      handle_list_block_with_array(e, array)
    elsif targetelements.include?(e.next_sibling.name)
      if check_attrs2(e.next_sibling, array) == true
        e.add(e.next_sibling)
        handle_list_block_with_array(e, array)
      end
    elsif e.name == e.next_sibling.name && !e.next_sibling.elements[1, "li"].nil?
      #if e.next_sibling.elements[1, "li"].attributes["num"].to_i > 1 || e.name == "ul"
      if e.next_sibling.elements[1, "li"].attributes["num"].to_i > 1 || e.name == "ul" || e.name == "ol"
        # 隣に同じ名前の要素がある場合はこちらの要素内に格納する
        handle_list_block_with_array(e.next_sibling, array)
        source = []
        e.next_sibling.each_child do |ec|
            source.push(ec)
        end
        source.each do |s|
          e.add(s)
        end
        e.next_sibling.remove
      end
    end
  end
end

def handle_list_block_with_hash(e, hash)
  # e要素の後にあるものを、
  # - テキスト要素
  # - インストラクション
  # - inlist属性のあるもの
  # - arrayに含まれるもの
  # であれば移動する
  if e.next_sibling.instance_of?(Text) || e.next_sibling.instance_of?(Instruction)
    e.add(e.next_sibling)
    handle_list_block_with_hash(e, hash)
  elsif e.next_sibling.instance_of?(Element)
    targetelements = hash.keys
    if !e.next_sibling.attributes["inlist"].nil?
      e.next_sibling.attributes.delete("inlist")
      e.add(e.next_sibling)
      handle_list_block_with_hash(e, hash)
    elsif targetelements.include?(e.next_sibling.name)
      if hash[e.next_sibling.name].nil? || check_attrs(e.next_sibling.attributes, hash[e.next_sibling.name]) == true
        e.add(e.next_sibling)
        handle_list_block_with_hash(e, hash)
      end
    elsif e.name == e.next_sibling.name && !e.next_sibling.elements[1, "li"].nil?
      #if e.next_sibling.elements[1, "li"].attributes["num"].to_i > 1 || e.name == "ul"
      if e.next_sibling.elements[1, "li"].attributes["num"].to_i > 1 || e.name == "ul" || e.name == "ol"
        # 隣に同じ名前の要素がある場合はこちらの要素内に格納する
        handle_list_block_with_hash(e.next_sibling, hash)
        source = []
        e.next_sibling.each_child do |ec|
            source.push(ec)
        end
        source.each  do |s|
          e.add(s)
        end
        e.next_sibling.remove
      end
    end
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

def appendix_num(num)
  # 付録用の採番
  %w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)[num]
end
