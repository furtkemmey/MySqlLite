//
//  ViewController.swift
//  MySqlLite
//
//  Created by KaiChieh on 02/03/2018.
//  Copyright © 2018 KaiChieh. All rights reserved.
//

import UIKit
import SQLite3

class ViewController: UIViewController {
    var currentButtonYPosition: CGFloat = 0
    var pkvGender: UIPickerView!
    var pkvClass: UIPickerView!
    let arrGender = ["F", "M"]
    let arrClass = ["mobile Phone", "Web design", "IOT develope"]
    //Sqlite 3
    var db: OpaquePointer?
    var dicRow = [String : Any?]() {  // single row, sync to screen
        didSet{
//            dicRow = arrTable[0] // get a dictionary from array dictionary
            txtNo.text = dicRow["stu_no"] as? String
            txtName.text = dicRow["name"] as? String
            txtGender.text = ((dicRow["gender"] as? Int) == 0) ? "女" : "難"
            if let aPic = dicRow["picture"] {
                imgPicture.image = UIImage(data: (aPic as? Data)!)
            }
            textPhone.text = dicRow["phone"] as? String
            textClass.text = dicRow["classes"] as? String
            textAddress.text = dicRow["address"] as? String
            textEmail.text = dicRow["email"] as? String
        }
    }
    var arrTable = Array<[String : Any?]>() // array data
    var currentRow = 0

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //keyboard Notification register
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)) , name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWilHild), name: .UIKeyboardDidHide, object: nil)

        pkvGender = UIPickerView()
        pkvGender.tag = 2 // the same as TextFiled tag
        pkvGender.delegate = self
        pkvGender.dataSource = self
        txtGender.inputView = pkvGender // input data from pickerView

        pkvClass = UIPickerView()
        pkvClass.tag = 4
        pkvClass.delegate = self
        pkvClass.dataSource = self
        textClass.inputView = pkvClass

        //sqlite3, get db connction
        if let delegateShard = UIApplication.shared.delegate as? AppDelegate {
            self.db = delegateShard.db
        }
    }
    @objc func keyboardWillShow(_ sender: Notification) {
        if let keyboardHeight = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
            // height we can use (not include keyboard height)
            let visiableHeight = view.frame.size.height - keyboardHeight
            if currentButtonYPosition > visiableHeight {
                //change button position
                view.frame.origin.y = -(currentButtonYPosition - visiableHeight + 16)
            }
        }
    }
    @objc func keyboardWilHild(){
        view.frame.origin.y = 0
    }
    // MARK: - IBOutlet
    @IBOutlet weak var txtNo: UITextField!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtGender: UITextField!
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var textPhone: UITextField!
    @IBOutlet weak var textClass: UITextField!
    @IBOutlet weak var textAddress: UITextField!
    @IBOutlet weak var textEmail: UITextField!
    @IBOutlet var textOutletCollection: [UITextField]!

    // MARK: - IBAction

    @IBAction func btnGoFirst(_ sender: UIButton) {
        currentRow = 0
        dicRow = arrTable[currentRow]
    }
    @IBAction func goLast(_ sender: UIButton) {
        currentRow = arrTable.count - 1
        dicRow = arrTable[currentRow]
    }
    @IBAction func didEndOnExit(_ sender: UITextField) {
        printLog("didEndOnExit")
    }
    @IBAction func editDidBegin(_ sender: UITextField) {
        currentButtonYPosition = sender.frame.origin.y + sender.frame.size.height // button position
//        print("editDidBegin")
//        printLog("editDidBegin")
        switch sender.tag {
        case 2:
            txtGender.text = arrGender[0]
            pkvGender.selectRow(0, inComponent: 0, animated: true)
        case 4:
            textClass.text = arrClass[0]
            pkvClass.selectRow(0, inComponent: 0, animated: true)
        case 0,3:
            sender.keyboardType = .numbersAndPunctuation
        case 6:
            sender.keyboardType = .emailAddress
        default:
            sender.keyboardType = .default
        }
    }
    @IBAction func editDidEnd(_ sender: UITextField) {
        print("editDidEnd")
        sender.resignFirstResponder()
    }
    @IBAction func tabView(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    @IBAction func btnQuery(_ sender: UIButton) {
        arrTable.removeAll()
        if db != nil {
            let sql = "select stu_no, name, gender, picture, phone, class, address, email from students order by stu_no"
            let cSql = sql.cString(using: .utf8)
            var statment: OpaquePointer? // result, statment

            sqlite3_prepare_v2(db, cSql!, -1, &statment, nil)
            if statment == nil {
                printLog("statment == nil")
            }
            while sqlite3_step(statment) == SQLITE_ROW {
                dicRow.removeAll()
                let stu_no = String(cString: sqlite3_column_text(statment, 0))
                let name = String(cString: sqlite3_column_text(statment, 1))
                let gender = sqlite3_column_int(statment, 2)
                //picture
                var imageData: Data?
                if let blobDataPoint = sqlite3_column_blob(statment, 3) {
                    let fileLength = sqlite3_column_bytes(statment, 3)
                    imageData = Data(bytes: blobDataPoint, count: Int(fileLength)) // get data

                } else { // bytes is zero
                    let aImage = UIImage(named: "DefaultPhoto.jpg")
                    imageData = UIImageJPEGRepresentation( aImage!, 0.8)

                }
                let phone = String(cString: sqlite3_column_text(statment, 4))
                let classes = String(cString: sqlite3_column_text(statment, 5))
                let address = String(cString: sqlite3_column_text(statment, 6))
                let email = String(cString: sqlite3_column_text(statment, 7))
//                printLog("stu_no is \(stu_no), nema is \(name), phone is \(phone)")

                dicRow["stu_no"] = stu_no
                dicRow["name"] = name
                dicRow["gender"] = Int(gender)
                dicRow["picture"] = imageData
                dicRow["phone"] = phone
                dicRow["classes"] = classes
                dicRow["address"] = address
                dicRow["email"] = email

                arrTable.append(dicRow)
            }
            sqlite3_finalize(statment)
            if arrTable.count > 0 {
                dicRow = arrTable[0] // get a dictionary from array dictionary

            }
        } // end if db != nil {
    }
    @IBAction func btnPrevious(_ sender: UIButton) {
        if currentRow - 1 >= 0 {
            currentRow -= 1
            dicRow = arrTable[currentRow] // get a dictionary from array dictionary
        }
    }
    @IBAction func btnNext(_ sender: UIButton) {
        if currentRow + 1 < arrTable.count {
            currentRow += 1
            dicRow = arrTable[currentRow]

        }
    }
    @IBAction func btnTake(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            show(imagePicker, sender: self) // show view
        } else {
            printLog("Can't find camera")
        }
    }
    @IBAction func btnPhotoLibrary(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .popover
        let popover = imagePicker.popoverPresentationController
        popover?.sourceView = sender // set show position near button
        popover?.sourceRect = sender.bounds
        popover?.permittedArrowDirections = .any
        show(imagePicker, sender: self)
    }
    @IBAction func btnInsert(_ sender: UIButton) {
        //insert into students(stu_no,name,gender,picture,phone,class,address,email) values('S106','name',0,NULL,'phone','mobile Phone','address','email')
        if txtNo.text == "" || txtName.text == "" {
            let alert = UIAlertController(title: "Cannt insert", message: "text is empty", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil ))
            self.present(alert, animated: true)
            return
        }
        if db != nil {
            let imgData = UIImageJPEGRepresentation(imgPicture.image!, 1)! //return Data
            let screenGender = txtGender.text == "難" ? 1 : 0
            let sql = String(format: "insert into students(stu_no,name,gender,picture,phone,class,address,email) values('%@','%@',%i,?,'%@','%@','%@','%@')",txtNo.text!,txtName.text!,screenGender,textPhone.text!,textClass.text!, textAddress.text!,textEmail.text!)
            print("insert sql = \(sql)")
            let cSql = sql.cString(using: .utf8)!
            var statement: OpaquePointer?
            sqlite3_prepare_v2(db, cSql, -1, &statement, nil)
            // first question mark '?' at sql
            sqlite3_bind_blob(statement, 1, imgData.bytes, Int32(imgData.count), nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                var newRow = [String : Any?]()
                newRow["stu_no"] = txtNo.text
                newRow["name"] = txtName.text
                newRow["gender"] = screenGender
                newRow["picture"] = imgData
                newRow["phone"] = textPhone.text
                newRow["classed"] = textClass.text
                newRow["address"] = textAddress.text
                newRow["email"] = textEmail.text

                arrTable.append(newRow)
                NSLocalizedString("DBInfo", tableName: "InfoPlist.strings", bundle: Bundle.main, value: "", comment: "")
                let alert = UIAlertController(title: "Insert", message: "Data has been insert", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil ))
                self.present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: "Insert fail", message: "Data insert fail", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .destructive , handler: nil ))
                self.present(alert, animated: true)
            }
            sqlite3_finalize(statement)
        }
    }
    @IBAction func btnUpdate(_ sender: UIButton) {
        //update students set name='Text',gender=1,picture=NULL,phone='5555443',class='Web design',address='北春路',email='ee@lle.yvtc.edu.tw' where stu_no = 'S02'
        if txtNo.text == "" || txtName.text == "" {
            let alert = UIAlertController(title: "Cannt modify", message: "text is empty", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil ))
            self.present(alert, animated: true)
            return
        }
        if db != nil {
            let imgData = UIImageJPEGRepresentation(imgPicture.image!, 1)! //return Data
            let screenGender = txtGender.text == "難" ? 1 : 0
            let sql = String(format: "update students set name='%@',gender=%i,picture=?,phone='%@',class='%@',address='%@',email='%@' where stu_no = '%@' ",txtName.text!,screenGender,textPhone.text!,textClass.text!, textAddress.text!,textEmail.text!,txtNo.text!).cString(using: .utf8)!
//            print("update sql = \(sql)")
            var statement: OpaquePointer?
            sqlite3_prepare_v2(db, sql, -1, &statement, nil)
                                         // first question mark '?' at sql
            sqlite3_bind_blob(statement, 1, imgData.bytes, Int32(imgData.count), nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                arrTable[currentRow]["name"] = txtName.text
                arrTable[currentRow]["gender"] = screenGender
                arrTable[currentRow]["picture"] = imgData
                arrTable[currentRow]["phone"] = textPhone.text
                arrTable[currentRow]["class"] = textClass.text
                arrTable[currentRow]["address"] = textAddress.text
                arrTable[currentRow]["email"] = textEmail.text


                let alert = UIAlertController(title: "modify", message: "Data has been modiyied", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil ))
                self.present(alert, animated: true)
            }
            sqlite3_finalize(statement)
        }
    }
    @IBAction func btnDelete(_ sender: UIButton) {
        //delete from students where stu_no='S106'
        if txtNo.text == "" {
            let alert = UIAlertController(title: "Cannt delete", message: "ID is empty", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil ))
            self.present(alert, animated: true)
            return
        }
        if db != nil {
            let sql = String(format: "delete from students where stu_no='%@'", txtNo.text!).cString(using: .utf8)!
            //            print("update sql = \(sql)")
            var statement: OpaquePointer?
            sqlite3_prepare_v2(db, sql, -1, &statement, nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                arrTable.remove(at: currentRow)
                for txt in textOutletCollection {
                    txt.text = ""
                }
                imgPicture.image = UIImage(named: "DefaultPhoto.jpg")
                if currentRow - 1 < 0 {
                    currentRow = 0
                } else {
                    currentRow -= 1
                }

                let alert = UIAlertController(title: "deleted", message: "Data has been deleted", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil ))
                self.present(alert, animated: true)
                dicRow = arrTable[currentRow] 
            }
            sqlite3_finalize(statement)
        }
    }

}

extension Data {
    var bytes: UnsafeRawPointer? {
        return (self as NSData).bytes
    }
}
//MARK: - UIImagePickerControllerDelegate, camera
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //get picture
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//        printLog("media information \(info)")
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imgPicture.image = image
            picker.dismiss(animated: true, completion: nil)
        }
    }

}

// MARK: - UIPickerViewDelegate
extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 2:
            return arrGender.count
        case 4:
            return arrClass.count
        default:
            return 0
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 2:
            return arrGender[row]
        case 4:
            return arrClass[row]
        default:
            return ""
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 2:
            txtGender.text = arrGender[row]
        case 4:
            textClass.text = arrClass[row]
        default:
            break
        }
    }
}

//MARK: - for debug log print
extension ViewController {
    func printLog<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line){
        #if DEBUG
            debugPrint("Line:\(line) \(method)(): \(message)")
//        #else
//            print("Line:\(line) \(method)(): \(message)")
        #endif
    }
}


