//
//  MainViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import Alamofire
import AlamofireImage
import CoreData

final class MainViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var songsContainerView: UIView!
    @IBOutlet private weak var albumsContainerView: UIView!
    @IBOutlet private weak var artistsContainerView: UIView!
    @IBOutlet private weak var playlistsContainerView: UIView!
    @IBOutlet private weak var recommendationsContainerView: UIView!
    
    //MARK: - Properties
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
    }
    
    // TODO: - Add check of containers for emptiness.
    private func configureContainers() {
        
    }
}
