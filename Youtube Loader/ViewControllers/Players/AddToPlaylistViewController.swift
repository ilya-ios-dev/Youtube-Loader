//
//  AddToPlaylistViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 02.02.2021.
//

import UIKit
import CoreData

enum CardViewState {
    case expanded
    case normal
}

final class AddToPlaylistViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var backingImageView: UIImageView!
    @IBOutlet private weak var dimmerView: UIView!
    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var cardViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var handleView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var saveButton: UIButton!
        
    //MARK: - Properties
    public var backingImage: UIImage?
    public var currentSong: Song?
    
    private var cardViewState : CardViewState = .normal
    private var cardPanStartingTopConstraint : CGFloat = 30.0
    private var fetchedResultsController: NSFetchedResultsController<Playlist>!
    private var dataSource: UITableViewDiffableDataSource<Int, Playlist>!
    private var snapshot: NSDiffableDataSourceSnapshot<Int, Playlist>!
    private var window: UIWindow? {
        return UIApplication.shared.windows.filter({$0.isKeyWindow}).first
    }
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    //MARK: - View Life Cycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showCard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        configureTapGesture()
        configurePanGesture()
        let nib = UINib(nibName: String(describing: PlaylistTableViewCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: PlaylistTableViewCell.cellIdentifier)
        tableView.delegate = self
        setupFetchedResultsController()
        setupDiffableDataSource()
    }
    
}

//MARK: - Actions
extension AddToPlaylistViewController {
    
    @IBAction private func saveButtonTapped(_ sender: Any) {
        guard let currentSong = currentSong else { return }
        guard let indexPath = tableView.indexPathForSelectedRow else { fatalError() }
        guard let playlist = dataSource.itemIdentifier(for: indexPath) else { return }
        currentSong.addToPlaylist(playlist)
        do {
            try context.save()
        } catch {
            print(error)
            showAlert(alertText: error.localizedDescription)
            return
        }
        dismiss(animated: true, completion: nil)
    }
    
    /// Tracks down Pan Gesture.
    /// Moves the `cardView` to one of the positions, depending on where the view is dragged to.
    @IBAction private func viewPanned(_ panRecognizer: UIPanGestureRecognizer) {
        let velocity = panRecognizer.velocity(in: self.view)
        let translation = panRecognizer.translation(in: self.view)
        
        switch panRecognizer.state {
        case .began:
            cardPanStartingTopConstraint = cardViewTopConstraint.constant
            
        case .changed:
            if self.cardPanStartingTopConstraint + translation.y > 30.0 {
                self.cardViewTopConstraint.constant = self.cardPanStartingTopConstraint + translation.y
            }
            
            // change the dimmer view alpha based on how much user has dragged
            dimmerView.alpha = dimAlphaWithCardTopConstraint(value: self.cardViewTopConstraint.constant)
            
        case .ended:
            // If the speed is too high, then the user wants to close the controller.
            if velocity.y > 1500.0 {
                hideCardAndGoBack()
                return
            }
            
            if let safeAreaHeight = window?.safeAreaLayoutGuide.layoutFrame.size.height,
               let bottomPadding = window?.safeAreaInsets.bottom {
                
                if self.cardViewTopConstraint.constant < (safeAreaHeight + bottomPadding) * 0.25 {
                    showCard(atState: .expanded)
                } else if self.cardViewTopConstraint.constant < (safeAreaHeight) - 70 {
                    showCard(atState: .normal)
                } else {
                    hideCardAndGoBack()
                }
            }
        default:
            break
        }
    }
    
    @IBAction private func dimmerViewTapped(_ tapRecognizer: UITapGestureRecognizer) {
        hideCardAndGoBack()
    }
}

//MARK: Animations
extension AddToPlaylistViewController {
    
    /// Animates the movement of the cardView depending on the state..
    /// - Parameter atState: CardView deployment position.
    private func showCard(atState: CardViewState = .normal) {
        
        self.view.layoutIfNeeded()
        
        if let safeAreaHeight = window?.safeAreaLayoutGuide.layoutFrame.size.height,
           let bottomPadding = window?.safeAreaInsets.bottom {
            
            if atState == .expanded {
                // if state is expanded, top constraint is 30pt away from safe area top
                cardViewTopConstraint.constant = 30.0
            } else {
                cardViewTopConstraint.constant = (safeAreaHeight + bottomPadding) / 2.0
            }
            
            cardPanStartingTopConstraint = cardViewTopConstraint.constant
        }
        
        // move card up from bottom animator
        let showCard = UIViewPropertyAnimator(duration: 0.25, curve: .easeIn, animations: {
            self.view.layoutIfNeeded()
        })
        
        // animate the dimmerView alpha together with the card move up animation
        showCard.addAnimations {
            self.dimmerView.alpha = 0.5
        }
        
        showCard.startAnimation()
    }
    
    /// Animates the disappearance of the cardView.
    private func hideCardAndGoBack() {
        self.view.layoutIfNeeded()
        
        if let safeAreaHeight = window?.safeAreaLayoutGuide.layoutFrame.size.height,
           let bottomPadding = window?.safeAreaInsets.bottom {
            
            // move the card view to bottom of screen
            cardViewTopConstraint.constant = safeAreaHeight + bottomPadding
        }
        
        // move card down to bottom animator
        let hideCard = UIViewPropertyAnimator(duration: 0.25, curve: .easeIn, animations: {
            self.view.layoutIfNeeded()
        })
        
        // animate the dimmerView alpha together with the card move down animation
        hideCard.addAnimations {
            self.dimmerView.alpha = 0.0
        }
        
        // when the animation completes, dismiss this view controller
        hideCard.addCompletion({ position in
            if position == .end {
                if(self.presentingViewController != nil) {
                    self.dismiss(animated: false, completion: nil)
                }
            }
        })
        
        hideCard.startAnimation()
    }
    
    /// Calculates the opacity of the dimmerView based on the distance to the top.
    /// If the cardView rises above the `.normal` state, the transparency does not change.
    /// - Parameter value: `CardView` distance to top.
    /// - Returns: The calculated transparency of the `dimmerView`..
    private func dimAlphaWithCardTopConstraint(value: CGFloat) -> CGFloat {
        let fullDimAlpha : CGFloat = 0.5
        
        // ensure safe area height and safe area bottom padding is not nil
        guard let safeAreaHeight = window?.safeAreaLayoutGuide.layoutFrame.size.height,
              let bottomPadding = window?.safeAreaInsets.bottom else {
            return fullDimAlpha
        }
        
        // when card view top constraint value is equal to this,
        // the dimmer view alpha is dimmest (0.5)
        let fullDimPosition = (safeAreaHeight + bottomPadding) / 2.0
        
        // when card view top constraint value is equal to this,
        // the dimmer view alpha is lightest (0.0)
        let noDimPosition = safeAreaHeight + bottomPadding
        
        // if card view top constraint is lesser than fullDimPosition
        // it is dimmest
        if value < fullDimPosition {
            return fullDimAlpha
        }
        
        // if card view top constraint is more than noDimPosition
        // it is dimmest
        if value > noDimPosition {
            return 0.0
        }
        
        // else return an alpha value in between 0.0 and 0.5 based on the top constraint value
        return fullDimAlpha * 1 - ((value - fullDimPosition) / fullDimPosition)
    }
}

//MARK: - Supporting Methods
extension AddToPlaylistViewController {
    
    /// Configures pan gesture for adjusting cardViewState.
    private func configurePanGesture() {
        let viewPan = UIPanGestureRecognizer(target: self, action: #selector(viewPanned(_:)))
        viewPan.delaysTouchesBegan = false
        viewPan.delaysTouchesEnded = false
        self.view.addGestureRecognizer(viewPan)
    }
    
    /// Configures the Tap Gesture to close the controller when the dimmerView is pressed.
    private func configureTapGesture() {
        let dimmerTap = UITapGestureRecognizer(target: self, action: #selector(dimmerViewTapped(_:)))
        dimmerView.addGestureRecognizer(dimmerTap)
        dimmerView.isUserInteractionEnabled = true
    }
    
    private func configureViews() {
        backingImageView.image = backingImage

        cardView.clipsToBounds = true
        cardView.layer.cornerRadius = 10.0
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        handleView.clipsToBounds = true
        handleView.layer.cornerRadius = handleView.frame.height / 2

        if let safeAreaHeight = window?.safeAreaLayoutGuide.layoutFrame.size.height,
           let bottomPadding = window?.safeAreaInsets.bottom {
            cardViewTopConstraint.constant = safeAreaHeight + bottomPadding
        }
        dimmerView.alpha = 0.0
    }
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest = Playlist.fetchRequest()
        
        let sort = NSSortDescriptor(key: "dateSave", ascending: true)
        request.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            setupSnapshot()
        } catch {
            print(error)
        }
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Playlist>()
        snapshot.appendSections([0])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true)
        }
    }
    
    private func setupDiffableDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, Playlist>(tableView: tableView, cellProvider: { (tableView, indexPath, playlist) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistTableViewCell.cellIdentifier) as! PlaylistTableViewCell
            cell.configure(name: playlist.name, songsCount: playlist.songs?.count, imageURL: playlist.thumbnails?.smallUrl)
            return cell
        })
        setupSnapshot()
    }
}

//MARK: - UITableViewDelegate
extension AddToPlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard saveButton.isHidden else { return }
        saveButton.alpha = 0
        saveButton.isHidden = false
        UIView.animate(withDuration: 0.325) {
            self.saveButton.alpha = 1
        }
    }
}

//MARK: - NSFetchedResultsControllerDelegate
extension AddToPlaylistViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}
