#!/usr/bin/ruby
$KCODE="utf-8"

require "MeCab"

#================================================================================
#   基準文書とそれ以外の文書の類似度を
#   TF-IDFベクトルのコサイン尺度で測り，関連の強い順にソートする
#================================================================================

directory_path = "./assignment_tfidf/"

# >>>>>>>>>>ファイルリスト作成<<<<<<<<<<
file_list = Dir::entries(directory_path)\
                .delete_if{|x| x == "." || x == ".."}\
                .sort\
                .collect{|file_name| directory_path + file_name}

# >>>>>>>>>>各ファイル毎にTFとIDFを計算<<<<<<<<<<
tf = Hash::new{|hash_parent, key1| hash_parent[key1] = Hash::new{|hash_child, key2| hash_child[key2] = 0}}
df = Hash::new{|hash, key| hash[key] = 0}
idf = Hash::new{|hash, key| hash[key] = 0}
parser = MeCab::Tagger.new("--node-format=%m,%f[0]\\n --eos-format='' ")

file_list.each { |file_path| 
    # 名詞リストを作成する．
    file = open(file_path).read
    noun_list = parser.parse(file)\
                      .split("\n")\
                      .collect{|elem| elem.split(",")}\
                      .select{|word_pos| word_pos[1] == "名詞"}\
                      .collect{|word_pos| word_pos[0]}

    # tfのカウント
    noun_list.each { |noun| 
        tf[file_path][noun] += 1
    } 

    # dfのカウント
    noun_list.uniq.each{|noun|
        df[noun] += 1
    }
}

# idfの計算
df.each_key { |key| 
    # idf[key] = Math::log10(1.0 + (file_list.length / df[key]) )
    idf[key] = 1.0 + Math::log10(file_list.length / df[key])
}


# >>>>>>>>>>TF−IDFベクトルの計算<<<<<<<<<<
tf_idf = Hash::new{|hash_parent, key1| hash_parent[key1] = Hash::new{|hash_child, key2| hash_child[key2] = 0}}
file_list.each { |file_path| 
    tf[file_path].each_key {|noun| 
        tf_idf[file_path][noun] = tf[file_path][noun] * idf[noun]
    }
}

# >>>>>>>>>>基準文書のTF-IDFと他のTF−IDFの比較<<<<<<<<<<
cos_scale = Hash::new{|hash, key| hash[key] = 0}
interest_file_name = file_list[0]
interest_vector_norm = 0.0

# 基準文書のTF-IDFベクトルのノルム計算
tf_idf[interest_file_name].keys.each { |noun| 
    interest_vector_norm += (tf_idf[interest_file_name][noun])**2
}
interest_vector_norm = Math::sqrt(interest_vector_norm)

file_list.each { |file_name| 
    # 基準文書と基準文書でコサイン尺度は計算しない
    if file_name == interest_file_name
        next
    end

    # 対象文書のTF−IDFのベクトルのノルム計算
    target_vector_norm = 0.0
    tf_idf[file_name].keys.each{|noun|
        target_vector_norm += (tf_idf[file_name][noun])**2
    }
    target_vector_norm= Math::sqrt(target_vector_norm)

    # 内積計算
    inner_product = 0.0

    word_list = (tf_idf[interest_file_name].keys) & (tf_idf[file_name].keys)
    word_list.each { |noun| 
        inner_product += tf_idf[interest_file_name][noun] * tf_idf[file_name][noun]
    }

    # コサイン尺度計算
    cos_scale[file_name] = (inner_product) / (interest_vector_norm * target_vector_norm)
}

# >>>>>>>>>>コサイン尺度の降順にソートし，表示する<<<<<<<<<<
cos_scale.sort{|a, b|b[1]<=>a[1]}.each { |elem| 
    puts elem[0] + " : " + elem[1].inspect
}
